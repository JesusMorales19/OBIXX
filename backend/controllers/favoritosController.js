import { query } from '../config/db.js';
import { handleDatabaseError, handleValidationError } from '../services/errorHandler.js';

/**
 * Agregar un trabajador a favoritos
 */
export const agregarFavorito = async (req, res) => {
  try {
    const { emailContratista, emailTrabajador } = req.body;

    if (!emailContratista || !emailTrabajador) {
      return handleValidationError(res, 'Email del contratista y del trabajador son requeridos');
    }

    // Verificar que el contratista existe
    const contratistaResult = await query(
      'SELECT email FROM contratistas WHERE email = $1',
      [emailContratista]
    );

    if (contratistaResult.rows.length === 0) {
      return handleValidationError(res, 'Contratista no encontrado', 404);
    }

    // Verificar que el trabajador existe
    const trabajadorResult = await query(
      'SELECT email FROM trabajadores WHERE email = $1',
      [emailTrabajador]
    );

    if (trabajadorResult.rows.length === 0) {
      return handleValidationError(res, 'Trabajador no encontrado', 404);
    }

    // Insertar favorito (si ya existe, no hará nada por el UNIQUE constraint)
    const result = await query(
      `INSERT INTO favoritos (email_contratista, email_trabajador)
       VALUES ($1, $2)
       ON CONFLICT (email_contratista, email_trabajador) DO NOTHING
       RETURNING *`,
      [emailContratista, emailTrabajador]
    );

    if (result.rows.length === 0) {
      return res.status(200).json({
        success: true,
        message: 'El trabajador ya estaba en favoritos',
        yaExistia: true,
      });
    }

    res.status(201).json({
      success: true,
      message: 'Trabajador agregado a favoritos',
      data: result.rows[0],
    });
  } catch (error) {
    handleDatabaseError(error, res, 'Error al agregar favorito');
  }
};

/**
 * Quitar un trabajador de favoritos
 */
export const quitarFavorito = async (req, res) => {
  try {
    const { emailContratista, emailTrabajador } = req.body;

    if (!emailContratista || !emailTrabajador) {
      return handleValidationError(res, 'Email del contratista y del trabajador son requeridos');
    }

    const result = await query(
      `DELETE FROM favoritos 
       WHERE email_contratista = $1 AND email_trabajador = $2
       RETURNING *`,
      [emailContratista, emailTrabajador]
    );

    if (result.rows.length === 0) {
      return handleValidationError(res, 'Favorito no encontrado', 404);
    }

    res.status(200).json({
      success: true,
      message: 'Trabajador quitado de favoritos',
    });
  } catch (error) {
    handleDatabaseError(error, res, 'Error al quitar favorito');
  }
};

/**
 * Verificar si un trabajador está en favoritos
 */
export const verificarFavorito = async (req, res) => {
  try {
    const { emailContratista, emailTrabajador } = req.query;

    if (!emailContratista || !emailTrabajador) {
      return handleValidationError(res, 'Email del contratista y del trabajador son requeridos');
    }

    const result = await query(
      'SELECT * FROM favoritos WHERE email_contratista = $1 AND email_trabajador = $2',
      [emailContratista, emailTrabajador]
    );

    const esFavorito = result.rows.length > 0;

    res.status(200).json({
      success: true,
      esFavorito: esFavorito,
    });
  } catch (error) {
    handleDatabaseError(error, res, 'Error al verificar favorito');
  }
};

/**
 * Listar todos los trabajadores favoritos de un contratista
 */
export const listarFavoritos = async (req, res) => {
  try {
    const { emailContratista } = req.query;

    if (!emailContratista) {
      return handleValidationError(res, 'Email del contratista es requerido');
    }

    const result = await query(
      `SELECT 
        t.nombre,
        t.apellido,
        t.username,
        t.email,
        t.telefono,
        c.nombre as categoria,
        t.experiencia,
        t.disponible,
        t.calificacion_promedio,
        t.foto_perfil,
        f.fecha_agregado
       FROM favoritos f
       INNER JOIN trabajadores t ON f.email_trabajador = t.email
       INNER JOIN categorias c ON t.categoria = c.id_categoria
       WHERE f.email_contratista = $1
       ORDER BY f.fecha_agregado DESC`,
      [emailContratista]
    );
    
    res.status(200).json({
      success: true,
      total: result.rows.length,
      favoritos: result.rows,
    });
  } catch (error) {
    handleDatabaseError(error, res, 'Error al listar favoritos');
  }
};

