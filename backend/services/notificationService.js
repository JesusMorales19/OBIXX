import { query } from '../config/db.js';
import { sendPushNotification } from './firebaseService.js';

const DEFAULT_EXPIRATION_MINUTES = 60;

export const registrarTokenDispositivo = async ({
  email,
  tipoUsuario,
  token,
  plataforma = 'desconocida',
}) => {
  if (!email || !tipoUsuario || !token) {
    throw new Error('Faltan datos para registrar el dispositivo.');
  }

  await query(
    `INSERT INTO dispositivos_notificaciones (email, tipo_usuario, token, plataforma)
     VALUES ($1, $2, $3, $4)
     ON CONFLICT (token) DO UPDATE
       SET email = EXCLUDED.email,
           tipo_usuario = EXCLUDED.tipo_usuario,
           plataforma = EXCLUDED.plataforma,
           actualizado_en = CURRENT_TIMESTAMP`,
    [email, tipoUsuario, token, plataforma]
  );
};

export const eliminarTokenDispositivo = async (token) => {
  if (!token) return;
  await query('DELETE FROM dispositivos_notificaciones WHERE token = $1', [token]);
};

export const obtenerTokensUsuario = async (email) => {
  if (!email) return [];
  const result = await query(
    `SELECT token
     FROM dispositivos_notificaciones
     WHERE email = $1`,
    [email]
  );
  return result.rows.map((row) => row.token);
};

export const crearNotificacion = async ({
  emailDestino,
  titulo,
  cuerpo,
  tipo = 'general',
  data = {},
  imagen = null,
  expiraEnMinutos = DEFAULT_EXPIRATION_MINUTES,
}) => {
  if (!emailDestino || !titulo || !cuerpo) {
    throw new Error('Faltan datos para crear la notificación.');
  }

  const dataJson = JSON.stringify(data || {});
  const result = await query(
    `INSERT INTO notificaciones_usuario (
        email_destino,
        titulo,
        cuerpo,
        tipo,
        data_json,
        imagen,
        expira_en
      )
      VALUES ($1, $2, $3, $4, $5, $6, CURRENT_TIMESTAMP + ($7 || ' minutes')::interval)
      RETURNING id_notificacion, expira_en`,
    [emailDestino, titulo, cuerpo, tipo, dataJson, imagen, String(expiraEnMinutos)]
  );

  return result.rows[0];
};

export const obtenerNotificacionesActivas = async ({ email, tipoUsuario }) => {
  const result = await query(
    `SELECT id_notificacion,
            titulo,
            cuerpo,
            tipo,
            data_json,
            imagen,
            leida,
            created_at,
            expira_en
       FROM notificaciones_usuario
      WHERE email_destino = $1
        AND (expira_en IS NULL OR expira_en > CURRENT_TIMESTAMP)
      ORDER BY created_at DESC`,
    [email]
  );

  return result.rows.map((row) => {
    let data = {};

    if (row.data_json != null) {
      if (typeof row.data_json === "string") {
        try {
          data = JSON.parse(row.data_json);
        } catch (error) {
          console.error("No se pudo parsear data_json:", error);
          data = {};
        }
      } else {
        data = row.data_json;
      }
    }

    return {
      id: row.id_notificacion,
      titulo: row.titulo,
      cuerpo: row.cuerpo,
      tipo: row.tipo,
      data,
      imagen: row.imagen,
      leida: row.leida,
      createdAt: row.created_at,
      expiraEn: row.expira_en,
    };
  });
};

export const marcarNotificacionesLeidas = async ({ email, ids }) => {
  if (!email || !Array.isArray(ids) || ids.length === 0) {
    return;
  }

  await query(
    `UPDATE notificaciones_usuario
        SET leida = TRUE,
            leida_en = CURRENT_TIMESTAMP
      WHERE email_destino = $1
        AND id_notificacion = ANY($2::int[])`,
    [email, ids]
  );
};

export const eliminarNotificacionesUsuario = async ({ email }) => {
  if (!email) {
    return;
  }

  await query(
    `DELETE FROM notificaciones_usuario
      WHERE email_destino = $1`,
    [email]
  );
};

export const notificarCalificacionTrabajador = async ({
  emailTrabajador,
  nombreContratista,
  emailContratista,
  estrellas,
  tituloTrabajo,
  contexto = 'finalizado',
}) => {
  try {
    const titulo = nombreContratista
      ? `Contratista: ${nombreContratista.toUpperCase()}`
      : 'Contratista';
    const nombreMensaje = nombreContratista && nombreContratista.trim().length > 0
      ? nombreContratista
      : emailContratista;

    const nombreTrabajo = tituloTrabajo && tituloTrabajo.trim().length > 0
      ? `"${tituloTrabajo.trim()}"`
      : 'el trabajo';

    const cuerpo =
      contexto === 'cancelado'
        ? `El contratista ${nombreMensaje} te ha desvinculado del trabajo ${nombreTrabajo} y registró tu calificación. Tu valoración fue de ${estrellas}/5 estrellas.`
        : `El contratista ${nombreMensaje} ha terminado el trabajo ${nombreTrabajo} y registró tu calificación. Tu valoración fue de ${estrellas}/5 estrellas.`;

    const registro = await crearNotificacion({
      emailDestino: emailTrabajador,
      titulo,
      cuerpo,
      tipo: 'calificacion_trabajador',
      data: {
        tipo: 'calificacion_trabajador',
        estrellas,
        nombreContratista,
        emailContratista,
        tituloTrabajo,
        contexto,
      },
    });

    const tokens = await obtenerTokensUsuario(emailTrabajador);
    if (Array.isArray(tokens) && tokens.length > 0) {
      await sendPushNotification({
        tokens,
        title: titulo,
        body: cuerpo,
        data: {
          tipo: 'calificacion_trabajador',
          notificacionId: registro?.id_notificacion ? String(registro.id_notificacion) : '',
          estrellas: String(estrellas),
          tituloTrabajo: tituloTrabajo ?? '',
          contexto,
        },
      });
    }
  } catch (error) {
    console.error('Error al notificar calificación al trabajador:', error);
  }
};

export const notificarInteresContratista = async ({
  emailTrabajador,
  nombreTrabajador,
  emailContratista,
  nombreContratista,
  tituloTrabajo,
}) => {
  try {
    const nombreContratistaUpper = nombreContratista
      ? `Contratista: ${nombreContratista.toUpperCase()}`
      : 'Contratista';
    const cuerpo = nombreContratista
      ? `El contratista ${nombreContratista} se ha interesado en ti. Mantente al tanto de tu WhatsApp, ahí te contactará.`
      : 'Un contratista se ha interesado en ti. Mantente al tanto de tu WhatsApp, ahí te contactará.';

    const registro = await crearNotificacion({
      emailDestino: emailTrabajador,
      titulo: nombreContratistaUpper,
      cuerpo,
      tipo: 'contratista_interesado',
      data: {
        tipo: 'contratista_interesado',
        nombreContratista,
        emailContratista,
        tituloTrabajo,
        nombreTrabajador,
      },
    });

    const tokens = await obtenerTokensUsuario(emailTrabajador);
    if (Array.isArray(tokens) && tokens.length > 0) {
      await sendPushNotification({
        tokens,
        title: nombreContratistaUpper,
        body: cuerpo,
        data: {
          tipo: 'contratista_interesado',
          notificacionId: registro?.id_notificacion
            ? String(registro.id_notificacion)
            : '',
          emailContratista,
          tituloTrabajo: tituloTrabajo ?? '',
        },
      });
    }
  } catch (error) {
    console.error('Error al notificar interés del contratista:', error);
  }
};

export const notificarCancelacionContratista = async ({
  emailTrabajador,
  emailContratista,
  nombreContratista,
  tituloTrabajo,
}) => {
  try {
    const titulo = nombreContratista
      ? `Contratista: ${nombreContratista.toUpperCase()}`
      : 'Contratista';
    const cuerpo = `${nombreContratista ?? 'El contratista'} ha cancelado la contratación. Ahora estás disponible hacia más proyectos y distintos contratistas.`;

    const registro = await crearNotificacion({
      emailDestino: emailTrabajador,
      titulo,
      cuerpo,
      tipo: 'cancelacion_contratista',
      data: {
        tipo: 'cancelacion_contratista',
        emailContratista,
        nombreContratista,
        tituloTrabajo,
      },
    });

    const tokens = await obtenerTokensUsuario(emailTrabajador);
    if (Array.isArray(tokens) && tokens.length > 0) {
      await sendPushNotification({
        tokens,
        title: titulo,
        body: cuerpo,
        data: {
          tipo: 'cancelacion_contratista',
          notificacionId: registro?.id_notificacion ? String(registro.id_notificacion) : '',
          emailContratista,
          tituloTrabajo: tituloTrabajo ?? '',
        },
      });
    }
  } catch (error) {
    console.error('Error al notificar cancelación del contratista:', error);
  }
};

export const notificarCancelacionTrabajador = async ({
  emailContratista,
  nombreTrabajador,
  emailTrabajador,
  tituloTrabajo,
  idAsignacion,
  tipoTrabajo,
}) => {
  try {
    const titulo = nombreTrabajador
      ? `Trabajador: ${nombreTrabajador.toUpperCase()}`
      : 'Trabajador';
    const cuerpo = `El trabajador perteneciente al proyecto "${tituloTrabajo ?? 'Trabajo'}" canceló su instancia.`;

    const registro = await crearNotificacion({
      emailDestino: emailContratista,
      titulo,
      cuerpo,
      tipo: 'solicitud_cancelada',
      data: {
        tipo: 'solicitud_cancelada',
        tituloTrabajo,
        emailTrabajador,
        idAsignacion,
        tipoTrabajo,
      },
    });

    const tokens = await obtenerTokensUsuario(emailContratista);
    if (Array.isArray(tokens) && tokens.length > 0) {
      await sendPushNotification({
        tokens,
        title: titulo,
        body: cuerpo,
        data: {
          tipo: 'solicitud_cancelada',
          notificacionId: registro?.id_notificacion
            ? String(registro.id_notificacion)
            : '',
          emailTrabajador,
          tituloTrabajo: tituloTrabajo ?? '',
          idAsignacion: idAsignacion != null ? String(idAsignacion) : '',
          tipoTrabajo: tipoTrabajo ?? '',
        },
      });
    }
  } catch (error) {
    console.error('Error al notificar cancelación realizada por el trabajador:', error);
  }
};

