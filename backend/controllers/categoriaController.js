import { query } from '../config/db.js';
import { handleDatabaseError } from '../services/errorHandler.js';

/**
 * Obtiene todas las categorías disponibles
 */
export const getCategorias = async (req, res) => {
  try {
    const result = await query(
      'SELECT id_categoria, nombre FROM categorias ORDER BY nombre ASC'
    );

    res.status(200).json({
      success: true,
      data: result.rows,
    });
  } catch (error) {
    handleDatabaseError(error, res, 'Error al obtener categorías');
  }
};










