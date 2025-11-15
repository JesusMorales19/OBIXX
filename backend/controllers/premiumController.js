import { query, getClient } from '../config/db.js';
import PDFDocument from 'pdfkit';
import { handleDatabaseError, handleError, handleValidationError } from '../services/errorHandler.js';

// ================================================
// VERIFICAR SI TIENE PREMIUM ACTIVO
// ================================================
export const verificarPremium = async (req, res) => {
  try {
    const { email } = req.query;

    if (!email) {
      return handleValidationError(res, 'El email del contratista es requerido');
    }

    // Verificar si tiene suscripción activa
    const suscripcionResult = await query(
      `SELECT s.*, p.nombre as plan_nombre, p.periodicidad, p.precio, p.id_plan
       FROM suscripciones_premium s
       INNER JOIN planes_premium p ON s.id_plan = p.id_plan
       WHERE s.email_contratista = $1 
       AND s.estado = 'activa' 
       AND s.fecha_fin > NOW()`,
      [email]
    );

    const tienePremium = suscripcionResult.rows.length > 0;
    const suscripcion = tienePremium ? suscripcionResult.rows[0] : null;

    res.json({
      success: true,
      tienePremium,
      suscripcion: suscripcion,
      id_plan_activo: suscripcion ? suscripcion.id_plan : null,
      periodicidad_activa: suscripcion ? suscripcion.periodicidad : null,
    });
  } catch (error) {
    handleDatabaseError(error, res, 'Error al verificar estado premium');
  }
};

// ================================================
// ACTIVAR SUSCRIPCIÓN PREMIUM (después del pago)
// ================================================
export const activarSuscripcion = async (req, res) => {
  const client = await getClient();
  try {
    await client.query('BEGIN');

    const {
      email_contratista,
      id_plan,
      guardar_tarjeta,
      auto_renovacion,
      metodo_pago,
    } = req.body;

    if (!email_contratista || !id_plan) {
      await client.query('ROLLBACK');
      return handleValidationError(res, 'Email del contratista e ID del plan son requeridos');
    }

    // Verificar que el plan existe
    const planResult = await client.query(
      'SELECT * FROM planes_premium WHERE id_plan = $1 AND activo = true',
      [id_plan]
    );

    if (planResult.rows.length === 0) {
      await client.query('ROLLBACK');
      return handleValidationError(res, 'Plan no encontrado o inactivo', 404);
    }

    const plan = planResult.rows[0];
    const fechaInicio = new Date();
    let fechaFin = new Date();

    // Calcular fecha de fin según periodicidad
    if (plan.periodicidad === 'mensual') {
      fechaFin.setMonth(fechaFin.getMonth() + 1);
    } else if (plan.periodicidad === 'anual') {
      fechaFin.setFullYear(fechaFin.getFullYear() + 1);
    }

    // Guardar método de pago si se solicitó
    let idMetodoPago = null;
    if (guardar_tarjeta && metodo_pago) {
      const metodoResult = await client.query(
        `INSERT INTO metodos_pago_contratista 
         (email_contratista, alias, marca, ultimos4, token_pasarela, es_predeterminado, activo)
         VALUES ($1, $2, $3, $4, $5, $6, $7)
         RETURNING id_metodo`,
        [
          email_contratista,
          metodo_pago.alias || 'Tarjeta principal',
          metodo_pago.marca,
          metodo_pago.ultimos4,
          metodo_pago.token_pasarela || 'SIMULADO',
          true,
          true,
        ]
      );
      idMetodoPago = metodoResult.rows[0].id_metodo;
    }

    // Crear suscripción
    const suscripcionResult = await client.query(
      `INSERT INTO suscripciones_premium 
       (email_contratista, id_plan, id_metodo_pago, fecha_inicio, fecha_fin, estado, auto_renovacion)
       VALUES ($1, $2, $3, $4, $5, $6, $7)
       RETURNING *`,
      [
        email_contratista,
        id_plan,
        idMetodoPago,
        fechaInicio,
        fechaFin,
        'activa',
        auto_renovacion || false,
      ]
    );

    const suscripcion = suscripcionResult.rows[0];

    // Registrar pago
    await client.query(
      `INSERT INTO pagos_premium 
       (id_suscripcion, id_metodo_pago, monto, moneda, status, referencia_pasarela)
       VALUES ($1, $2, $3, $4, $5, $6)`,
      [
        suscripcion.id_suscripcion,
        idMetodoPago,
        plan.precio,
        'MXN',
        'completado',
        `SIM-${Date.now()}`,
      ]
    );

    // Actualizar contratista con suscripción activa
    await client.query(
      `UPDATE contratistas 
       SET id_suscripcion_activa = $1, 
           id_metodo_pago_preferido = $2,
           auto_renovacion_activa = $3
       WHERE email = $4`,
      [
        suscripcion.id_suscripcion,
        idMetodoPago,
        auto_renovacion || false,
        email_contratista,
      ]
    );

    await client.query('COMMIT');

    res.json({
      success: true,
      message: 'Suscripción premium activada exitosamente',
      suscripcion,
    });
  } catch (error) {
    await client.query('ROLLBACK');
    handleDatabaseError(error, res, 'Error al activar suscripción premium');
  } finally {
    client.release();
  }
};

// ================================================
// CANCELAR SUSCRIPCIÓN PREMIUM
// ================================================
export const cancelarSuscripcion = async (req, res) => {
  const client = await getClient();
  try {
    await client.query('BEGIN');

    const { email_contratista } = req.body;

    if (!email_contratista) {
      await client.query('ROLLBACK');
      return handleValidationError(res, 'El email del contratista es requerido');
    }

    // Verificar que tiene una suscripción activa
    const suscripcionResult = await client.query(
      `SELECT s.* FROM suscripciones_premium s
       WHERE s.email_contratista = $1 
       AND s.estado = 'activa' 
       AND s.fecha_fin > NOW()`,
      [email_contratista]
    );

    if (suscripcionResult.rows.length === 0) {
      await client.query('ROLLBACK');
      return handleValidationError(res, 'No tienes una suscripción premium activa para cancelar', 404);
    }

    const suscripcion = suscripcionResult.rows[0];

    // Actualizar el estado de la suscripción a 'cancelada'
    await client.query(
      `UPDATE suscripciones_premium 
       SET estado = 'cancelada', 
           fecha_cancelacion = NOW(),
           actualizado_en = NOW()
       WHERE id_suscripcion = $1`,
      [suscripcion.id_suscripcion]
    );

    // Actualizar el contratista para remover la referencia a la suscripción activa
    await client.query(
      `UPDATE contratistas 
       SET id_suscripcion_activa = NULL,
           auto_renovacion_activa = false
       WHERE email = $1`,
      [email_contratista]
    );

    await client.query('COMMIT');

    console.log(`✅ Suscripción cancelada para: ${email_contratista}`);

    res.json({
      success: true,
      mensaje: 'Suscripción premium cancelada exitosamente',
      suscripcion_cancelada: {
        id_suscripcion: suscripcion.id_suscripcion,
        fecha_cancelacion: new Date().toISOString(),
      },
    });
  } catch (error) {
    await client.query('ROLLBACK');
    handleDatabaseError(error, res, 'Error al cancelar la suscripción premium');
  } finally {
    client.release();
  }
};

// ================================================
// OBTENER TRABAJOS ACTIVOS PARA ADMINISTRACIÓN
// ================================================
export const obtenerTrabajosAdministracion = async (req, res) => {
  try {
    const { email } = req.query;

    if (!email) {
      return handleValidationError(res, 'El email del contratista es requerido');
    }

    // Verificar que tiene premium activo
    const premiumResult = await query(
      `SELECT s.* FROM suscripciones_premium s
       WHERE s.email_contratista = $1 
       AND s.estado = 'activa' 
       AND s.fecha_fin > NOW()`,
      [email]
    );

    if (premiumResult.rows.length === 0) {
      return res.status(403).json({
        success: false,
        error: 'No tienes una suscripción premium activa',
      });
    }

    // Obtener trabajos activos de largo plazo
    const trabajosResult = await query(
      `SELECT 
         id_trabajo_largo,
         titulo,
         descripcion,
         direccion,
         fecha_inicio,
         fecha_fin,
         estado,
         presupuesto,
         moneda_presupuesto,
         created_at
       FROM trabajos_largo_plazo
       WHERE email_contratista = $1 
       AND estado = 'activo'
       ORDER BY created_at DESC`,
      [email]
    );

    res.json({
      success: true,
      trabajos: trabajosResult.rows,
    });
  } catch (error) {
    handleDatabaseError(error, res, 'Error al obtener trabajos para administración');
  }
};

// ================================================
// REGISTRAR/ACTUALIZAR PRESUPUESTO
// ================================================
export const registrarPresupuesto = async (req, res) => {
  try {
    const { email_contratista, id_trabajo_largo, presupuesto, moneda = 'MXN' } = req.body;

    if (!email_contratista || !id_trabajo_largo || presupuesto === undefined) {
      return handleValidationError(res, 'Email, ID de trabajo y presupuesto son requeridos');
    }

    if (presupuesto < 0) {
      return handleValidationError(res, 'El presupuesto debe ser mayor o igual a 0');
    }

    // Verificar que tiene premium activo
    const premiumResult = await query(
      `SELECT s.* FROM suscripciones_premium s
       WHERE s.email_contratista = $1 
       AND s.estado = 'activa' 
       AND s.fecha_fin > NOW()`,
      [email_contratista]
    );

    if (premiumResult.rows.length === 0) {
      return res.status(403).json({
        success: false,
        error: 'No tienes una suscripción premium activa',
      });
    }

    // Verificar que el trabajo pertenece al contratista
    const trabajoResult = await query(
      'SELECT * FROM trabajos_largo_plazo WHERE id_trabajo_largo = $1 AND email_contratista = $2',
      [id_trabajo_largo, email_contratista]
    );

    if (trabajoResult.rows.length === 0) {
      return handleValidationError(res, 'Trabajo no encontrado o no tienes permisos', 404);
    }

    // Actualizar presupuesto y moneda
    await query(
      'UPDATE trabajos_largo_plazo SET presupuesto = $1, moneda_presupuesto = $2 WHERE id_trabajo_largo = $3',
      [presupuesto, moneda, id_trabajo_largo]
    );

    res.json({
      success: true,
      message: 'Presupuesto registrado exitosamente',
    });
  } catch (error) {
    handleDatabaseError(error, res, 'Error al registrar presupuesto');
  }
};

// ================================================
// REGISTRAR HORAS LABORALES
// ================================================
export const registrarHoras = async (req, res) => {
  try {
    const {
      id_asignacion,
      email_trabajador,
      email_contratista,
      fecha,
      horas,
      minutos,
      nota,
    } = req.body;

    if (!id_asignacion || !email_trabajador || !email_contratista || !fecha || !horas) {
      return handleValidationError(res, 'Todos los campos son requeridos');
    }

    // Verificar que tiene premium activo
    const premiumResult = await query(
      `SELECT s.* FROM suscripciones_premium s
       WHERE s.email_contratista = $1 
       AND s.estado = 'activa' 
       AND s.fecha_fin > NOW()`,
      [email_contratista]
    );

    if (premiumResult.rows.length === 0) {
      return res.status(403).json({
        success: false,
        error: 'No tienes una suscripción premium activa',
      });
    }

    // Insertar o actualizar horas (usando ON CONFLICT para evitar duplicados)
    await query(
      `INSERT INTO horas_laborales 
       (id_asignacion, email_trabajador, email_contratista, fecha, horas, minutos, nota)
       VALUES ($1, $2, $3, $4, $5, $6, $7)
       ON CONFLICT (id_asignacion, email_trabajador, fecha)
       DO UPDATE SET horas = EXCLUDED.horas, minutos = EXCLUDED.minutos, nota = EXCLUDED.nota, actualizado_en = CURRENT_TIMESTAMP`,
      [id_asignacion, email_trabajador, email_contratista, fecha, horas, minutos || 0, nota || null]
    );

    res.json({
      success: true,
      message: 'Horas registradas exitosamente',
    });
  } catch (error) {
    handleDatabaseError(error, res, 'Error al registrar horas');
  }
};

// ================================================
// CONFIGURAR SUELDO DE TRABAJADOR
// ================================================
export const configurarSueldo = async (req, res) => {
  try {
    const {
      id_asignacion,
      id_trabajo_largo,
      email_trabajador,
      email_contratista,
      tipo_periodo,
      monto_periodo,
      moneda = 'MXN',
      horas_requeridas_periodo,
    } = req.body;

    if (!id_asignacion || !id_trabajo_largo || !email_trabajador || !email_contratista || !tipo_periodo || !monto_periodo) {
      return handleValidationError(res, 'Todos los campos son requeridos');
    }

    // Verificar que tiene premium activo
    const premiumResult = await query(
      `SELECT s.* FROM suscripciones_premium s
       WHERE s.email_contratista = $1 
       AND s.estado = 'activa' 
       AND s.fecha_fin > NOW()`,
      [email_contratista]
    );

    if (premiumResult.rows.length === 0) {
      return res.status(403).json({
        success: false,
        error: 'No tienes una suscripción premium activa',
      });
    }

    // Verificar que la asignación existe y obtener los emails desde asignaciones_trabajo
    const asignacionResult = await query(
      `SELECT email_trabajador, email_contratista 
       FROM asignaciones_trabajo 
       WHERE id_asignacion = $1`,
      [id_asignacion]
    );

    if (asignacionResult.rows.length === 0) {
      return handleValidationError(res, 'Asignación no encontrada', 404);
    }

    const asignacion = asignacionResult.rows[0];
    
    // Verificar que los emails coinciden con la asignación
    if (asignacion.email_trabajador !== email_trabajador || asignacion.email_contratista !== email_contratista) {
      return handleValidationError(res, 'Los emails no coinciden con la asignación');
    }

    // Insertar o actualizar configuración (sin email_trabajador ni email_contratista)
    await query(
      `INSERT INTO configuracion_pagos_trabajadores 
       (id_asignacion, id_trabajo_largo, tipo_periodo, monto_periodo, moneda, horas_requeridas_periodo)
       VALUES ($1, $2, $3, $4, $5, $6)
       ON CONFLICT (id_asignacion)
       DO UPDATE SET 
         tipo_periodo = EXCLUDED.tipo_periodo,
         monto_periodo = EXCLUDED.monto_periodo,
         moneda = EXCLUDED.moneda,
         horas_requeridas_periodo = EXCLUDED.horas_requeridas_periodo,
         actualizado_en = CURRENT_TIMESTAMP`,
      [
        id_asignacion,
        id_trabajo_largo,
        tipo_periodo,
        monto_periodo,
        moneda,
        horas_requeridas_periodo || 0,
      ]
    );

    res.json({
      success: true,
      message: 'Sueldo configurado exitosamente',
    });
  } catch (error) {
    handleDatabaseError(error, res, 'Error al configurar sueldo');
  }
};

// ================================================
// OBTENER TRABAJADORES DE UN TRABAJO
// ================================================
export const obtenerTrabajadoresTrabajo = async (req, res) => {
  try {
    const { id_trabajo_largo, email_contratista } = req.query;

    if (!id_trabajo_largo || !email_contratista) {
      return handleValidationError(res, 'ID de trabajo y email del contratista son requeridos');
    }

    // Verificar que tiene premium activo
    const premiumResult = await query(
      `SELECT s.* FROM suscripciones_premium s
       WHERE s.email_contratista = $1 
       AND s.estado = 'activa' 
       AND s.fecha_fin > NOW()`,
      [email_contratista]
    );

    if (premiumResult.rows.length === 0) {
      return res.status(403).json({
        success: false,
        error: 'No tienes una suscripción premium activa',
      });
    }

    // Obtener trabajadores asignados al trabajo
    // Primero verificar qué asignaciones existen para debug
    const debugResult = await query(
      `SELECT 
         a.id_asignacion,
         a.email_trabajador,
         a.tipo_trabajo,
         a.id_trabajo,
         a.estado,
         a.email_contratista
       FROM asignaciones_trabajo a
       WHERE a.id_trabajo = $1
       AND a.email_contratista = $2`,
      [id_trabajo_largo, email_contratista]
    );
    
    console.log('🔍 Debug - Asignaciones encontradas:', JSON.stringify(debugResult.rows, null, 2));

    // Obtener trabajadores asignados al trabajo (más flexible con estados)
    const trabajadoresResult = await query(
      `SELECT 
         a.id_asignacion,
         a.email_trabajador,
         t.nombre,
         t.apellido,
         t.telefono,
         a.estado as estado_asignacion,
         a.tipo_trabajo,
         c.tipo_periodo,
         c.monto_periodo,
         c.moneda,
         c.horas_requeridas_periodo
       FROM asignaciones_trabajo a
       INNER JOIN trabajadores t ON a.email_trabajador = t.email
       LEFT JOIN configuracion_pagos_trabajadores c ON a.id_asignacion = c.id_asignacion
       WHERE (a.tipo_trabajo = 'largo' OR a.tipo_trabajo = 'largo_plazo')
       AND a.id_trabajo = $1
       AND a.email_contratista = $2
       AND a.estado NOT IN ('cancelado', 'finalizado', 'completado')
       ORDER BY t.nombre, t.apellido`,
      [id_trabajo_largo, email_contratista]
    );
    
    console.log('✅ Trabajadores encontrados:', trabajadoresResult.rows.length);

    res.json({
      success: true,
      trabajadores: trabajadoresResult.rows,
    });
  } catch (error) {
    handleDatabaseError(error, res, 'Error al obtener trabajadores');
  }
};

// ================================================
// GENERAR/DESCARGAR NÓMINA
// ================================================
export const generarNomina = async (req, res) => {
  try {
    const {
      id_trabajo_largo,
      email_contratista,
      periodo_inicio,
      periodo_fin,
    } = req.body;

    if (!id_trabajo_largo || !email_contratista || !periodo_inicio || !periodo_fin) {
      return handleValidationError(res, 'Todos los campos son requeridos');
    }

    // Verificar que tiene premium activo
    const premiumResult = await query(
      `SELECT s.* FROM suscripciones_premium s
       WHERE s.email_contratista = $1 
       AND s.estado = 'activa' 
       AND s.fecha_fin > NOW()`,
      [email_contratista]
    );

    if (premiumResult.rows.length === 0) {
      return res.status(403).json({
        success: false,
        error: 'No tienes una suscripción premium activa',
      });
    }

    // Obtener trabajo y presupuesto
    const trabajoResult = await query(
      'SELECT * FROM trabajos_largo_plazo WHERE id_trabajo_largo = $1 AND email_contratista = $2',
      [id_trabajo_largo, email_contratista]
    );

    if (trabajoResult.rows.length === 0) {
      return handleValidationError(res, 'Trabajo no encontrado', 404);
    }

    const trabajo = trabajoResult.rows[0];
    const presupuestoTotal = trabajo.presupuesto || 0;

    // Obtener gastos extras del período
    const gastosExtrasResult = await query(
      `SELECT fecha_gasto, descripcion, monto
       FROM gastos_extras
       WHERE id_trabajo_largo = $1
       AND email_contratista = $2
       AND fecha_gasto >= $3
       AND fecha_gasto <= $4
       ORDER BY fecha_gasto ASC`,
      [id_trabajo_largo, email_contratista, periodo_inicio, periodo_fin]
    );

    const gastosExtras = gastosExtrasResult.rows || [];
    const totalGastosExtras = gastosExtras.reduce((sum, gasto) => sum + parseFloat(gasto.monto || 0), 0);
    const detalleGastosExtras = gastosExtras.map(g => ({
      fecha: g.fecha_gasto,
      descripcion: g.descripcion,
      monto: parseFloat(g.monto || 0),
    }));

    // Obtener trabajadores con configuración de pago
    const trabajadoresResult = await query(
      `SELECT 
         a.id_asignacion,
         a.email_trabajador,
         t.nombre,
         t.apellido,
         c.tipo_periodo,
         c.monto_periodo,
         c.moneda,
         c.horas_requeridas_periodo
       FROM asignaciones_trabajo a
       INNER JOIN trabajadores t ON a.email_trabajador = t.email
       INNER JOIN configuracion_pagos_trabajadores c ON a.id_asignacion = c.id_asignacion
       WHERE (a.tipo_trabajo = 'largo' OR a.tipo_trabajo = 'largo_plazo')
       AND a.id_trabajo = $1
       AND a.email_contratista = $2
       AND a.estado NOT IN ('cancelado', 'finalizado', 'completado')`,
      [id_trabajo_largo, email_contratista]
    );

    console.log('🔍 Trabajadores con configuración de pago:', trabajadoresResult.rows.length);

    // Si no hay trabajadores con configuración de pago, permitir generar nómina vacía
    if (trabajadoresResult.rows.length === 0) {
      // Generar nómina sin trabajadores (solo con presupuesto)
      const saldoRestante = parseFloat(presupuestoTotal) || 0;
      
      try {
        const saldoRestanteConGastos = saldoRestante - totalGastosExtras;
        const nominaResult = await query(
          `INSERT INTO nominas_generadas 
           (id_trabajo_largo, email_contratista, periodo_inicio, periodo_fin, 
            presupuesto_total, total_pagado_trabajadores, total_gastos_extras, saldo_restante, 
            detalle_trabajadores, detalle_gastos_extras)
           VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
           RETURNING *`,
          [
            id_trabajo_largo,
            email_contratista,
            periodo_inicio,
            periodo_fin,
            presupuestoTotal || 0,
            0,
            totalGastosExtras,
            saldoRestanteConGastos,
            JSON.stringify([]),
            JSON.stringify(detalleGastosExtras),
          ]
        );

        return res.json({
          success: true,
          nomina: nominaResult.rows[0] || {},
          detalle: [],
          gastos_extras: detalleGastosExtras,
          total_gastos_extras: totalGastosExtras,
          mensaje: 'Nómina generada. No hay trabajadores con sueldo configurado.',
        });
      } catch (dbError) {
        console.error('❌ Error al insertar nómina vacía:', dbError);
        return handleError(dbError, res, 'Error al guardar la nómina. Asegúrate de tener trabajadores con sueldo configurado.');
      }
    }

    // Calcular horas trabajadas y pagos para cada trabajador
    const detalleTrabajadores = [];
    let totalPagado = 0;

    for (const trabajador of trabajadoresResult.rows) {
      // Sumar horas trabajadas en el período
      const horasResult = await query(
        `SELECT COALESCE(SUM(horas + minutos/60.0), 0) as total_horas
         FROM horas_laborales
         WHERE id_asignacion = $1
         AND fecha >= $2
         AND fecha <= $3`,
        [trabajador.id_asignacion, periodo_inicio, periodo_fin]
      );

      const totalHoras = parseFloat(horasResult.rows[0].total_horas) || 0;
      const horasRequeridas = parseFloat(trabajador.horas_requeridas_periodo) || 0;
      const montoPeriodo = parseFloat(trabajador.monto_periodo) || 0;

      // Calcular monto a pagar (proporcional si no completó las horas)
      let montoPagado = 0;
      if (horasRequeridas > 0 && totalHoras >= horasRequeridas) {
        montoPagado = montoPeriodo;
      } else if (horasRequeridas > 0 && totalHoras > 0) {
        // Pago proporcional
        montoPagado = (totalHoras / horasRequeridas) * montoPeriodo;
      } else if (horasRequeridas === 0) {
        // Si no hay horas requeridas, paga el monto completo
        montoPagado = montoPeriodo;
      }

      totalPagado += montoPagado;

      detalleTrabajadores.push({
        email_trabajador: trabajador.email_trabajador,
        nombre: `${trabajador.nombre} ${trabajador.apellido}`,
        horas_trabajadas: totalHoras,
        monto_pagado: montoPagado,
      });
    }

    // Calcular saldo restante (presupuesto - sueldos - gastos extras)
    const saldoRestante = parseFloat(presupuestoTotal) - totalPagado - totalGastosExtras;

    // Guardar nómina (sin el constraint de saldo para evitar errores)
    let nominaResult;
    try {
      nominaResult = await query(
        `INSERT INTO nominas_generadas 
         (id_trabajo_largo, email_contratista, periodo_inicio, periodo_fin, 
          presupuesto_total, total_pagado_trabajadores, total_gastos_extras, saldo_restante, 
          detalle_trabajadores, detalle_gastos_extras)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
         RETURNING *`,
        [
          id_trabajo_largo,
          email_contratista,
          periodo_inicio,
          periodo_fin,
          presupuestoTotal,
          totalPagado,
          totalGastosExtras,
          saldoRestante,
          JSON.stringify(detalleTrabajadores),
          JSON.stringify(detalleGastosExtras),
        ]
      );
    } catch (dbError) {
      console.error('❌ Error al insertar nómina:', dbError);
      // Si falla por constraint, intentar sin el constraint
      if (dbError.constraint === 'ck_nomina_saldo') {
        // Recalcular saldo para que coincida exactamente
        const saldoRecalculado = parseFloat(presupuestoTotal) - totalPagado - totalGastosExtras;
        nominaResult = await query(
          `INSERT INTO nominas_generadas 
           (id_trabajo_largo, email_contratista, periodo_inicio, periodo_fin, 
            presupuesto_total, total_pagado_trabajadores, total_gastos_extras, saldo_restante, 
            detalle_trabajadores, detalle_gastos_extras)
           VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
           RETURNING *`,
          [
            id_trabajo_largo,
            email_contratista,
            periodo_inicio,
            periodo_fin,
            presupuestoTotal,
            totalPagado,
            totalGastosExtras,
            saldoRecalculado,
            JSON.stringify(detalleTrabajadores),
            JSON.stringify(detalleGastosExtras),
          ]
        );
      } else {
        throw dbError;
      }
    }

    if (!nominaResult || nominaResult.rows.length === 0) {
      return handleError(new Error('No se pudo guardar la nómina'), res, 'Error al guardar la nómina en la base de datos');
    }

    // Obtener información del contratista para el PDF
    const contratistaResult = await query(
      'SELECT nombre, apellido FROM contratistas WHERE email = $1',
      [email_contratista]
    );
    const contratista = contratistaResult.rows[0] || {};

    // Generar PDF
    const pdfBuffer = await generarPDFNomina({
      trabajo: {
        titulo: trabajo.titulo || 'Sin título',
        descripcion: trabajo.descripcion || '',
      },
      contratista: {
        nombre: `${contratista.nombre || ''} ${contratista.apellido || ''}`.trim() || email_contratista,
        email: email_contratista,
      },
      periodo: {
        inicio: periodo_inicio,
        fin: periodo_fin,
      },
      presupuesto: presupuestoTotal,
      totalPagado: totalPagado,
      totalGastosExtras: totalGastosExtras,
      gastosExtras: detalleGastosExtras,
      saldoRestante: saldoRestante,
      trabajadores: detalleTrabajadores,
    });

    // Convertir PDF a base64
    const pdfBase64 = pdfBuffer.toString('base64');

    // Actualizar nómina con el PDF en base64 (no crítico si falla)
    try {
      await query(
        `UPDATE nominas_generadas 
         SET archivo_base64 = $1 
         WHERE id_nomina = $2`,
        [pdfBase64, nominaResult.rows[0].id_nomina]
      );
      console.log('✅ PDF guardado en base de datos');
    } catch (updateError) {
      console.error('⚠️ Error al guardar PDF en BD (no crítico):', updateError);
      // Continuar aunque falle el UPDATE, el PDF se devuelve en la respuesta
    }

    // Actualizar el objeto nomina con el PDF para la respuesta
    const nominaConPDF = {
      ...nominaResult.rows[0],
      archivo_base64: pdfBase64,
    };

    res.json({
      success: true,
      nomina: nominaConPDF,
      detalle: detalleTrabajadores || [],
      gastos_extras: detalleGastosExtras || [],
      total_gastos_extras: totalGastosExtras,
      pdf_base64: pdfBase64,
    });
  } catch (error) {
    handleError(error, res, 'Error al generar nómina');
  }
};

// ================================================
// FUNCIÓN PARA GENERAR PDF DE NÓMINA
// ================================================
const generarPDFNomina = async (datos) => {
  return new Promise((resolve, reject) => {
    try {
      const doc = new PDFDocument({ margin: 50, size: 'LETTER' });
      const chunks = [];

      doc.on('data', (chunk) => chunks.push(chunk));
      doc.on('end', () => resolve(Buffer.concat(chunks)));
      doc.on('error', reject);

      // Colores
      const colorAzul = '#1F4E79';
      const colorGris = '#666666';
      const colorVerde = '#28a745';

      // Encabezado
      doc
        .fillColor(colorAzul)
        .fontSize(24)
        .font('Helvetica-Bold')
        .text('NÓMINA DE PAGOS', { align: 'center', y: 50 });

      // Información del trabajo
      doc
        .fillColor('#000000')
        .fontSize(12)
        .font('Helvetica')
        .text('TRABAJO:', 50, 110)
        .font('Helvetica-Bold')
        .text(datos.trabajo.titulo, 120, 110);

      // Información del contratista
      doc
        .font('Helvetica')
        .text('CONTRATISTA:', 50, 130)
        .font('Helvetica-Bold')
        .text(datos.contratista.nombre, 150, 130);

      // Período
      const fechaInicio = new Date(datos.periodo.inicio).toLocaleDateString('es-MX');
      const fechaFin = new Date(datos.periodo.fin).toLocaleDateString('es-MX');
      doc
        .font('Helvetica')
        .text('PERÍODO:', 50, 150)
        .font('Helvetica-Bold')
        .text(`${fechaInicio} - ${fechaFin}`, 120, 150);

      // Línea separadora
      doc
        .strokeColor(colorAzul)
        .lineWidth(2)
        .moveTo(50, 180)
        .lineTo(562, 180)
        .stroke();

      // Tabla de trabajadores
      let yPos = 210;
      doc
        .fillColor(colorAzul)
        .fontSize(14)
        .font('Helvetica-Bold')
        .text('DETALLE DE TRABAJADORES', 50, yPos);

      yPos += 30;

      // Encabezados de tabla
      doc
        .fillColor('#FFFFFF')
        .rect(50, yPos, 512, 25)
        .fill()
        .fillColor(colorAzul)
        .fontSize(10)
        .font('Helvetica-Bold')
        .text('TRABAJADOR', 60, yPos + 8)
        .text('HORAS', 280, yPos + 8)
        .text('MONTO A PAGAR', 380, yPos + 8, { align: 'right' });

      yPos += 25;

      // Filas de trabajadores
      if (datos.trabajadores.length === 0) {
        doc
          .fillColor('#000000')
          .font('Helvetica')
          .text('No hay trabajadores con sueldo configurado', 60, yPos + 8);
        yPos += 25;
      } else {
        datos.trabajadores.forEach((trabajador, index) => {
          const isEven = index % 2 === 0;
          doc
            .fillColor(isEven ? '#F5F5F5' : '#FFFFFF')
            .rect(50, yPos, 512, 25)
            .fill();

          doc
            .fillColor('#000000')
            .fontSize(10)
            .font('Helvetica')
            .text(trabajador.nombre, 60, yPos + 8)
            .text(`${trabajador.horas_trabajadas.toFixed(2)} hrs`, 280, yPos + 8)
            .text(`$${trabajador.monto_pagado.toFixed(2)}`, 380, yPos + 8, { align: 'right', width: 170 });

          yPos += 25;
        });
      }

      // Línea separadora antes de gastos extras
      yPos += 10;
      doc
        .strokeColor(colorGris)
        .lineWidth(1)
        .moveTo(50, yPos)
        .lineTo(562, yPos)
        .stroke();

      // Tabla de gastos extras
      if (datos.gastosExtras && datos.gastosExtras.length > 0) {
        yPos += 20;
        doc
          .fillColor(colorAzul)
          .fontSize(14)
          .font('Helvetica-Bold')
          .text('GASTOS EXTRAS', 50, yPos);

        yPos += 30;

        // Encabezados de tabla de gastos
        doc
          .fillColor('#FFFFFF')
          .rect(50, yPos, 512, 25)
          .fill()
          .fillColor(colorAzul)
          .fontSize(10)
          .font('Helvetica-Bold')
          .text('FECHA', 60, yPos + 8)
          .text('DESCRIPCIÓN', 150, yPos + 8)
          .text('MONTO', 450, yPos + 8, { align: 'right' });

        yPos += 25;

        // Filas de gastos extras
        datos.gastosExtras.forEach((gasto, index) => {
          const isEven = index % 2 === 0;
          doc
            .fillColor(isEven ? '#F5F5F5' : '#FFFFFF')
            .rect(50, yPos, 512, 25)
            .fill();

          const fechaGasto = new Date(gasto.fecha).toLocaleDateString('es-MX');
          doc
            .fillColor('#000000')
            .fontSize(10)
            .font('Helvetica')
            .text(fechaGasto, 60, yPos + 8)
            .text(gasto.descripcion || 'Sin descripción', 150, yPos + 8, { width: 280 })
            .text(`$${parseFloat(gasto.monto || 0).toFixed(2)}`, 450, yPos + 8, { align: 'right', width: 112 });

          yPos += 25;
        });

        // Total de gastos extras
        yPos += 5;
        doc
          .fillColor('#000000')
          .fontSize(11)
          .font('Helvetica-Bold')
          .text('Total Gastos Extras:', 50, yPos)
          .text(`$${parseFloat(datos.totalGastosExtras || 0).toFixed(2)}`, 450, yPos, { align: 'right', width: 112 });

        yPos += 20;
      }

      // Línea separadora antes del resumen
      yPos += 10;
      doc
        .strokeColor(colorGris)
        .lineWidth(1)
        .moveTo(50, yPos)
        .lineTo(562, yPos)
        .stroke();

      // Resumen financiero
      yPos += 20;
      doc
        .fillColor(colorAzul)
        .fontSize(14)
        .font('Helvetica-Bold')
        .text('RESUMEN FINANCIERO', 50, yPos);

      yPos += 30;

      doc
        .fillColor('#000000')
        .fontSize(11)
        .font('Helvetica')
        .text('Presupuesto Total:', 50, yPos)
        .font('Helvetica-Bold')
        .text(`$${parseFloat(datos.presupuesto).toFixed(2)}`, 400, yPos, { align: 'right', width: 112 });

      yPos += 25;

      doc
        .font('Helvetica')
        .text('Total Pagado a Trabajadores:', 50, yPos)
        .font('Helvetica-Bold')
        .text(`$${parseFloat(datos.totalPagado).toFixed(2)}`, 400, yPos, { align: 'right', width: 112 });

      yPos += 25;

      if (datos.totalGastosExtras && datos.totalGastosExtras > 0) {
        doc
          .font('Helvetica')
          .text('Total Gastos Extras:', 50, yPos)
          .font('Helvetica-Bold')
          .text(`$${parseFloat(datos.totalGastosExtras).toFixed(2)}`, 400, yPos, { align: 'right', width: 112 });

        yPos += 25;
      }

      doc
        .font('Helvetica')
        .text('Saldo Restante:', 50, yPos)
        .fillColor(colorVerde)
        .font('Helvetica-Bold')
        .text(`$${parseFloat(datos.saldoRestante).toFixed(2)}`, 400, yPos, { align: 'right', width: 112 });

      // Pie de página
      const pageHeight = doc.page.height;
      doc
        .fillColor(colorGris)
        .fontSize(8)
        .font('Helvetica')
        .text(
          `Generado el ${new Date().toLocaleDateString('es-MX')} a las ${new Date().toLocaleTimeString('es-MX')}`,
          50,
          pageHeight - 50,
          { align: 'center', width: 512 }
        );

      doc.end();
    } catch (error) {
      reject(error);
    }
  });
};

// ================================================
// REGISTRAR GASTOS EXTRAS
// ================================================
export const registrarGastoExtra = async (req, res) => {
  try {
    const {
      id_trabajo_largo,
      email_contratista,
      fecha_gasto,
      monto,
      descripcion,
    } = req.body;

    if (!id_trabajo_largo || !email_contratista || !fecha_gasto || !monto || !descripcion) {
      return handleValidationError(res, 'Todos los campos son requeridos');
    }

    // Verificar que tiene premium activo
    const premiumResult = await query(
      `SELECT s.* FROM suscripciones_premium s
       WHERE s.email_contratista = $1 
       AND s.estado = 'activa' 
       AND s.fecha_fin > NOW()`,
      [email_contratista]
    );

    if (premiumResult.rows.length === 0) {
      return res.status(403).json({
        success: false,
        error: 'No tienes una suscripción premium activa',
      });
    }

    // Verificar que el trabajo existe y pertenece al contratista
    const trabajoResult = await query(
      'SELECT * FROM trabajos_largo_plazo WHERE id_trabajo_largo = $1 AND email_contratista = $2',
      [id_trabajo_largo, email_contratista]
    );

    if (trabajoResult.rows.length === 0) {
      return handleValidationError(res, 'Trabajo no encontrado', 404);
    }

    // Insertar gasto extra
    const result = await query(
      `INSERT INTO gastos_extras 
       (id_trabajo_largo, email_contratista, fecha_gasto, monto, descripcion)
       VALUES ($1, $2, $3, $4, $5)
       RETURNING *`,
      [id_trabajo_largo, email_contratista, fecha_gasto, monto, descripcion]
    );

    res.json({
      success: true,
      gasto: result.rows[0],
    });
  } catch (error) {
    handleDatabaseError(error, res, 'Error al registrar gasto extra');
  }
};

// ================================================
// OBTENER GASTOS EXTRAS DE UN TRABAJO
// ================================================
export const obtenerGastosExtras = async (req, res) => {
  try {
    const { id_trabajo_largo, email_contratista, periodo_inicio, periodo_fin } = req.query;

    if (!id_trabajo_largo || !email_contratista) {
      return handleValidationError(res, 'id_trabajo_largo y email_contratista son requeridos');
    }

    // Verificar que tiene premium activo
    const premiumResult = await query(
      `SELECT s.* FROM suscripciones_premium s
       WHERE s.email_contratista = $1 
       AND s.estado = 'activa' 
       AND s.fecha_fin > NOW()`,
      [email_contratista]
    );

    if (premiumResult.rows.length === 0) {
      return res.status(403).json({
        success: false,
        error: 'No tienes una suscripción premium activa',
      });
    }

    // Construir query con filtro de período si se proporciona
    let querySQL = `
      SELECT * FROM gastos_extras
      WHERE id_trabajo_largo = $1 AND email_contratista = $2
    `;
    const params = [id_trabajo_largo, email_contratista];

    if (periodo_inicio && periodo_fin) {
      querySQL += ' AND fecha_gasto >= $3 AND fecha_gasto <= $4';
      params.push(periodo_inicio, periodo_fin);
    }

    querySQL += ' ORDER BY fecha_gasto DESC, creado_en DESC';

    const result = await query(querySQL, params);

    res.json({
      success: true,
      gastos: result.rows || [],
    });
  } catch (error) {
    handleDatabaseError(error, res, 'Error al obtener gastos extras');
  }
};

// ================================================
// REINICIAR HORAS DE TRABAJADORES DESPUÉS DE DESCARGAR NÓMINA
// ================================================
export const reiniciarHorasTrabajadores = async (req, res) => {
  try {
    const {
      id_trabajo_largo,
      email_contratista,
      periodo_inicio,
      periodo_fin,
    } = req.body;

    if (!id_trabajo_largo || !email_contratista || !periodo_inicio || !periodo_fin) {
      return handleValidationError(res, 'Todos los campos son requeridos');
    }

    // Verificar que tiene premium activo
    const premiumResult = await query(
      `SELECT s.* FROM suscripciones_premium s
       WHERE s.email_contratista = $1 
       AND s.estado = 'activa' 
       AND s.fecha_fin > NOW()`,
      [email_contratista]
    );

    if (premiumResult.rows.length === 0) {
      return res.status(403).json({
        success: false,
        error: 'No tienes una suscripción premium activa',
      });
    }

    // Obtener la nómina generada para este período
    // Nota: Las fechas pueden venir en diferentes formatos, así que usamos comparación de fechas
    const nominaResult = await query(
      `SELECT * FROM nominas_generadas
       WHERE id_trabajo_largo = $1
       AND email_contratista = $2
       AND DATE(periodo_inicio) = DATE($3)
       AND DATE(periodo_fin) = DATE($4)
       ORDER BY generado_en DESC
       LIMIT 1`,
      [id_trabajo_largo, email_contratista, periodo_inicio, periodo_fin]
    );

    if (nominaResult.rows.length === 0) {
      console.error('❌ No se encontró nómina para:', { id_trabajo_largo, email_contratista, periodo_inicio, periodo_fin });
      return handleValidationError(res, 'No se encontró nómina generada para este período', 404);
    }

    const nomina = nominaResult.rows[0];
    const totalPagadoTrabajadores = parseFloat(nomina.total_pagado_trabajadores || 0);
    const totalGastosExtras = parseFloat(nomina.total_gastos_extras || 0);
    const totalGastado = totalPagadoTrabajadores + totalGastosExtras;

    console.log('📊 Datos de la nómina:', {
      totalPagadoTrabajadores,
      totalGastosExtras,
      totalGastado,
    });

    // Obtener el presupuesto actual del trabajo
    const trabajoResult = await query(
      'SELECT presupuesto FROM trabajos_largo_plazo WHERE id_trabajo_largo = $1 AND email_contratista = $2',
      [id_trabajo_largo, email_contratista]
    );

    if (trabajoResult.rows.length === 0) {
      return handleValidationError(res, 'Trabajo no encontrado', 404);
    }

    const presupuestoActual = parseFloat(trabajoResult.rows[0].presupuesto || 0);
    let nuevoPresupuesto = presupuestoActual - totalGastado;

    console.log('💰 Cálculo de presupuesto:', {
      presupuestoActual,
      totalGastado,
      nuevoPresupuesto,
    });

    // Validar que el nuevo presupuesto no sea negativo
    if (nuevoPresupuesto < 0) {
      console.warn(`⚠️ Advertencia: El presupuesto resultaría negativo (${nuevoPresupuesto}). Se establecerá en 0.`);
      nuevoPresupuesto = 0;
    }

    // Actualizar el presupuesto del trabajo
    const updateResult = await query(
      'UPDATE trabajos_largo_plazo SET presupuesto = $1 WHERE id_trabajo_largo = $2 AND email_contratista = $3',
      [nuevoPresupuesto, id_trabajo_largo, email_contratista]
    );

    console.log('✅ UPDATE ejecutado:', {
      rowsAffected: updateResult.rowCount,
      nuevoPresupuesto,
      id_trabajo_largo,
      email_contratista,
    });

    // Verificar que se actualizó correctamente
    const verifyResult = await query(
      'SELECT presupuesto FROM trabajos_largo_plazo WHERE id_trabajo_largo = $1 AND email_contratista = $2',
      [id_trabajo_largo, email_contratista]
    );

    if (verifyResult.rows.length > 0) {
      const presupuestoVerificado = parseFloat(verifyResult.rows[0].presupuesto || 0);
      console.log('✅ Presupuesto verificado después del UPDATE:', presupuestoVerificado);
      
      if (Math.abs(presupuestoVerificado - nuevoPresupuesto) > 0.01) {
        console.error('❌ ERROR: El presupuesto no se actualizó correctamente!', {
          esperado: nuevoPresupuesto,
          obtenido: presupuestoVerificado,
        });
      }
    }

    // Obtener todas las asignaciones activas del trabajo
    const asignacionesResult = await query(
      `SELECT a.id_asignacion, a.email_trabajador
       FROM asignaciones_trabajo a
       WHERE (a.tipo_trabajo = 'largo' OR a.tipo_trabajo = 'largo_plazo')
       AND a.id_trabajo = $1
       AND a.email_contratista = $2
       AND a.estado NOT IN ('cancelado', 'finalizado', 'completado')`,
      [id_trabajo_largo, email_contratista]
    );

    // Eliminar todas las horas registradas en el período para cada trabajador
    let totalHorasEliminadas = 0;

    if (asignacionesResult.rows.length > 0) {
      for (const asignacion of asignacionesResult.rows) {
        const deleteResult = await query(
          `DELETE FROM horas_laborales
           WHERE id_asignacion = $1
           AND fecha >= $2
           AND fecha <= $3`,
          [asignacion.id_asignacion, periodo_inicio, periodo_fin]
        );

        totalHorasEliminadas += deleteResult.rowCount || 0;
      }
    }

    // Eliminar gastos extras del período
    const gastosEliminados = await query(
      `DELETE FROM gastos_extras
       WHERE id_trabajo_largo = $1
       AND email_contratista = $2
       AND fecha_gasto >= $3
       AND fecha_gasto <= $4`,
      [id_trabajo_largo, email_contratista, periodo_inicio, periodo_fin]
    );

    console.log(`✅ Reinicio completado:`);
    console.log(`   - Horas eliminadas: ${totalHorasEliminadas} registros`);
    console.log(`   - Gastos extras eliminados: ${gastosEliminados.rowCount || 0} registros`);
    console.log(`   - Presupuesto actualizado: $${presupuestoActual.toFixed(2)} -> $${nuevoPresupuesto.toFixed(2)}`);
    console.log(`   - Total gastado en este período: $${totalGastado.toFixed(2)} (Sueldos: $${totalPagadoTrabajadores.toFixed(2)} + Gastos: $${totalGastosExtras.toFixed(2)})`);

    res.json({
      success: true,
      mensaje: `Reinicio completado para el período ${periodo_inicio} - ${periodo_fin}`,
      horas_eliminadas: totalHorasEliminadas,
      gastos_eliminados: gastosEliminados.rowCount || 0,
      trabajadores_afectados: asignacionesResult.rows.length,
      presupuesto_anterior: presupuestoActual,
      presupuesto_actualizado: nuevoPresupuesto,
      total_gastado: totalGastado,
      total_sueldos: totalPagadoTrabajadores,
      total_gastos_extras: totalGastosExtras,
    });
  } catch (error) {
    handleDatabaseError(error, res, 'Error al reiniciar horas de trabajadores');
  }
};

