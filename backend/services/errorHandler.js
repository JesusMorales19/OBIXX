/**
 * Servicio centralizado para manejo de errores
 * Mantiene toda la funcionalidad original pero centraliza el código
 */

/**
 * Maneja errores de base de datos y retorna respuesta apropiada
 * @param {Error} error - Error capturado
 * @param {Object} res - Objeto de respuesta de Express
 * @param {string} defaultMessage - Mensaje de error por defecto
 * @param {number} defaultStatus - Código de estado HTTP por defecto (500)
 */
export const handleDatabaseError = (error, res, defaultMessage = 'Error en la base de datos', defaultStatus = 500) => {
  console.error('Error en base de datos:', error);
  
  // Errores específicos de PostgreSQL
  if (error.code) {
    switch (error.code) {
      case '23505': // Violación de constraint único
        return res.status(400).json({
          success: false,
          error: 'Ya existe un registro con estos datos',
        });
      case '23503': // Violación de foreign key
        return res.status(400).json({
          success: false,
          error: 'Referencia inválida a otra tabla',
        });
      case '23502': // Violación de NOT NULL
        return res.status(400).json({
          success: false,
          error: 'Faltan campos requeridos',
        });
      case '42P01': // Tabla no existe
        return res.status(500).json({
          success: false,
          error: 'Error de configuración de base de datos',
        });
      default:
        break;
    }
  }
  
  // Error genérico
  res.status(defaultStatus).json({
    success: false,
    error: defaultMessage,
    details: process.env.NODE_ENV === 'development' ? error.message : undefined,
  });
};

/**
 * Maneja errores de validación
 * @param {Object} res - Objeto de respuesta de Express
 * @param {string} message - Mensaje de error
 * @param {number} statusCode - Código de estado HTTP (por defecto 400)
 */
export const handleValidationError = (res, message, statusCode = 400) => {
  return res.status(statusCode).json({
    success: false,
    error: message,
  });
};

/**
 * Maneja errores genéricos
 * @param {Error} error - Error capturado
 * @param {Object} res - Objeto de respuesta de Express
 * @param {string} defaultMessage - Mensaje de error por defecto
 * @param {number} defaultStatus - Código de estado HTTP por defecto (500)
 */
export const handleError = (error, res, defaultMessage = 'Error en el servidor', defaultStatus = 500) => {
  console.error('Error:', error);
  console.error('Stack trace:', error.stack);
  
  res.status(defaultStatus).json({
    success: false,
    error: defaultMessage,
    details: process.env.NODE_ENV === 'development' ? error.message : undefined,
  });
};

/**
 * Wrapper para manejar errores en funciones async
 * @param {Function} fn - Función async a ejecutar
 * @returns {Function} - Función wrapper que maneja errores
 */
export const asyncHandler = (fn) => {
  return (req, res, next) => {
    Promise.resolve(fn(req, res, next)).catch((error) => {
      handleError(error, res);
    });
  };
};

/**
 * Valida que los campos requeridos estén presentes
 * @param {Object} data - Datos a validar
 * @param {Array<string>} requiredFields - Campos requeridos
 * @returns {Object|null} - Objeto con error si falta algún campo, null si todo está bien
 */
export const validateRequiredFields = (data, requiredFields) => {
  const missingFields = requiredFields.filter(field => !data[field]);
  
  if (missingFields.length > 0) {
    return {
      success: false,
      error: `Faltan campos requeridos: ${missingFields.join(', ')}`,
    };
  }
  
  return null;
};

