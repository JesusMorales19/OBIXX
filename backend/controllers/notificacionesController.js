import { query } from '../config/db.js';
import {
  registrarTokenDispositivo,
  eliminarTokenDispositivo,
  obtenerNotificacionesActivas,
  marcarNotificacionesLeidas,
  eliminarNotificacionesUsuario,
  notificarInteresContratista,
  notificarCancelacionContratista,
} from '../services/notificationService.js';
import { handleDatabaseError, handleError } from '../services/errorHandler.js';
import {
  expirarSolicitudesPendientes,
  marcarSolicitudesComoRechazadas,
} from '../services/solicitudesService.js';

export const registrarToken = async (req, res) => {
  try {
    const { email, tipoUsuario, token, plataforma } = req.body;

    if (!email || !tipoUsuario || !token) {
      return handleValidationError(res, 'email, tipoUsuario y token son requeridos');
    }

    await registrarTokenDispositivo({
      email,
      tipoUsuario,
      token,
      plataforma,
    });

    return res.status(200).json({
      success: true,
      message: 'Token registrado correctamente',
    });
  } catch (error) {
    handleDatabaseError(error, res, 'Error interno al registrar token');
  }
};

export const eliminarToken = async (req, res) => {
  try {
    const { token } = req.body;
    if (!token) {
      return handleValidationError(res, 'Token requerido');
    }

    await eliminarTokenDispositivo(token);

    return res.status(200).json({
      success: true,
      message: 'Token eliminado correctamente',
    });
  } catch (error) {
    handleDatabaseError(error, res, 'Error interno al eliminar token');
  }
};

export const listarNotificaciones = async (req, res) => {
  try {
    const { email, tipoUsuario } = req.query;
    if (!email || !tipoUsuario) {
      return handleValidationError(res, 'email y tipoUsuario son requeridos');
    }

    await expirarSolicitudesPendientes();

    const notificaciones = await obtenerNotificacionesActivas({ email, tipoUsuario });

    return res.status(200).json({
      success: true,
      total: notificaciones.length,
      notificaciones,
    });
  } catch (error) {
    handleDatabaseError(error, res, 'Error interno al listar notificaciones');
  }
};

export const marcarLeidas = async (req, res) => {
  try {
    const { email, ids } = req.body;
    if (!email || !Array.isArray(ids) || ids.length === 0) {
      return handleValidationError(res, 'email y ids son requeridos');
    }

    await marcarNotificacionesLeidas({ email, ids });

    return res.status(200).json({
      success: true,
      message: 'Notificaciones actualizadas',
    });
  } catch (error) {
    handleDatabaseError(error, res, 'Error interno al marcar notificaciones como leídas');
  }
};

export const eliminarNotificaciones = async (req, res) => {
  try {
    const { email } = req.body;

    if (!email) {
      return handleValidationError(res, 'email es requerido');
    }

    const notificacionesResult = await query(
      `SELECT id_notificacion, data_json
         FROM notificaciones_usuario
        WHERE email_destino = $1`,
      [email]
    );

    const solicitudesPendientesIds = [];

    notificacionesResult.rows.forEach((row) => {
      const rawData = row.data_json;
      if (!rawData) return;

      let data = rawData;
      if (typeof rawData === 'string') {
        try {
          data = JSON.parse(rawData);
        } catch (error) {
          data = null;
        }
      }

      if (data && data.solicitudId) {
        const parsed = Number(data.solicitudId);
        if (!Number.isNaN(parsed)) {
          solicitudesPendientesIds.push(parsed);
        }
      }
    });

    if (solicitudesPendientesIds.length > 0) {
      await marcarSolicitudesComoRechazadas({
        ids: solicitudesPendientesIds,
      });
    }

    await eliminarNotificacionesUsuario({ email });

    return res.status(200).json({
      success: true,
      message: 'Notificaciones eliminadas correctamente',
    });
  } catch (error) {
    handleDatabaseError(error, res, 'Error interno al eliminar notificaciones');
  }
};

export const registrarInteresContratista = async (req, res) => {
  try {
    const {
      emailContratista,
      emailTrabajador,
      nombreContratista,
      nombreTrabajador,
      tipoTrabajo,
      idTrabajo,
    } = req.body;

    if (!emailContratista || !emailTrabajador) {
      return handleValidationError(res, 'emailContratista y emailTrabajador son requeridos');
    }

    let nombreContratistaFinal = nombreContratista;
    let nombreTrabajadorFinal = nombreTrabajador;
    let tituloTrabajo = null;

    try {
      const contratistaResult = await query(
        'SELECT nombre, apellido FROM contratistas WHERE email = $1',
        [emailContratista]
      );

      if (
        (!nombreContratistaFinal || nombreContratistaFinal.trim().length === 0) &&
        contratistaResult.rows.length > 0
      ) {
        const c = contratistaResult.rows[0];
        nombreContratistaFinal = `${c?.nombre ?? ''} ${c?.apellido ?? ''}`.trim();
      }
    } catch (error) {
      console.error('Error al obtener información del contratista:', error);
    }

    try {
      const trabajadorResult = await query(
        'SELECT nombre, apellido FROM trabajadores WHERE email = $1',
        [emailTrabajador]
      );

      if (
        (!nombreTrabajadorFinal || nombreTrabajadorFinal.trim().length === 0) &&
        trabajadorResult.rows.length > 0
      ) {
        const t = trabajadorResult.rows[0];
        nombreTrabajadorFinal = `${t?.nombre ?? ''} ${t?.apellido ?? ''}`.trim();
      }
    } catch (error) {
      console.error('Error al obtener información del trabajador:', error);
    }

    if (tipoTrabajo && idTrabajo) {
      const tablaTrabajo =
        tipoTrabajo === 'corto' ? 'trabajos_corto_plazo' : 'trabajos_largo_plazo';
      const campoId =
        tipoTrabajo === 'corto' ? 'id_trabajo_corto' : 'id_trabajo_largo';
      try {
        const trabajoResult = await query(
          `SELECT titulo FROM ${tablaTrabajo} WHERE ${campoId} = $1`,
          [idTrabajo]
        );
        if (trabajoResult.rows.length > 0) {
          tituloTrabajo = trabajoResult.rows[0].titulo;
        }
      } catch (error) {
        console.error('Error al obtener título del trabajo:', error);
      }
    }

    await notificarInteresContratista({
      emailTrabajador,
      nombreTrabajador: nombreTrabajadorFinal,
      emailContratista,
      nombreContratista: nombreContratistaFinal,
      tituloTrabajo,
    });

    return res.status(200).json({
      success: true,
      message: 'Notificación enviada correctamente',
    });
  } catch (error) {
    handleError(error, res, 'Error interno al registrar interés del contratista');
  }
};

export const registrarCancelacionContratista = async (req, res) => {
  try {
    const {
      emailContratista,
      emailTrabajador,
      nombreContratista,
      tipoTrabajo,
      idTrabajo,
    } = req.body;

    if (!emailContratista || !emailTrabajador) {
      return handleValidationError(res, 'emailContratista y emailTrabajador son requeridos');
    }

    let nombreContratistaFinal = nombreContratista;
    let tituloTrabajo = null;

    try {
      const contratistaResult = await query(
        'SELECT nombre, apellido FROM contratistas WHERE email = $1',
        [emailContratista]
      );

      if (
        (!nombreContratistaFinal || nombreContratistaFinal.trim().length === 0) &&
        contratistaResult.rows.length > 0
      ) {
        const c = contratistaResult.rows[0];
        nombreContratistaFinal = `${c?.nombre ?? ''} ${c?.apellido ?? ''}`.trim();
      }
    } catch (error) {
      console.error('Error al obtener información del contratista:', error);
    }

    if (tipoTrabajo && idTrabajo) {
      const tablaTrabajo =
        tipoTrabajo === 'corto' ? 'trabajos_corto_plazo' : 'trabajos_largo_plazo';
      const campoId =
        tipoTrabajo === 'corto' ? 'id_trabajo_corto' : 'id_trabajo_largo';
      try {
        const trabajoResult = await query(
          `SELECT titulo FROM ${tablaTrabajo} WHERE ${campoId} = $1`,
          [idTrabajo]
        );
        if (trabajoResult.rows.length > 0) {
          tituloTrabajo = trabajoResult.rows[0].titulo;
        }
      } catch (error) {
        console.error('Error al obtener título del trabajo:', error);
      }
    }

    await notificarCancelacionContratista({
      emailTrabajador,
      emailContratista,
      nombreContratista: nombreContratistaFinal,
      tituloTrabajo,
    });

    return res.status(200).json({
      success: true,
      message: 'Notificación de cancelación enviada correctamente',
    });
  } catch (error) {
    handleError(error, res, 'Error interno al registrar cancelación del contratista');
  }
};

