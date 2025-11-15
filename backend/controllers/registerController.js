import { query } from '../config/db.js';
import { extractUsernameFromEmail, convertDateFormat } from '../utils/emailUtils.js';
import { hashPassword } from '../utils/passwordUtils.js';
import { handleDatabaseError, handleValidationError } from '../services/errorHandler.js';

/**
 * Registra un nuevo contratista
 */
export const registerContratista = async (req, res) => {
  try {
    const { nombre, apellido, fechaNacimiento, email, genero, telefono, password, fotoBase64 } = req.body;

    // Validar campos requeridos
    if (!nombre || !apellido || !fechaNacimiento || !email || !telefono || !password) {
      return handleValidationError(res, 'Todos los campos son requeridos');
    }

    // Extraer el user del email
    const user = extractUsernameFromEmail(email);
    
    // Convertir fecha de formato DD/MM/YYYY a YYYY-MM-DD
    const fechaFormateada = convertDateFormat(fechaNacimiento);

    // Verificar si el email ya existe
    const emailCheck = await query(
      'SELECT email FROM contratistas WHERE email = $1',
      [email]
    );

    if (emailCheck.rows.length > 0) {
      return handleValidationError(res, 'El email ya está registrado', 409);
    }

    // Verificar si el username ya existe
    const userCheck = await query(
      'SELECT username FROM contratistas WHERE username = $1',
      [user]
    );

    let finalUser = user;

    if (userCheck.rows.length > 0) {
      // Si el username ya existe, añadir un número al final
      let counter = 1;
      let uniqueUser = `${user}${counter}`;
      
      while (true) {
        const check = await query(
          'SELECT username FROM contratistas WHERE username = $1',
          [uniqueUser]
        );
        
        if (check.rows.length === 0) {
          break;
        }
        counter++;
        uniqueUser = `${user}${counter}`;
      }
      
      finalUser = uniqueUser;
    }

    // Encriptar la contraseña antes de guardarla
    const hashedPassword = await hashPassword(password);

    // Insertar contratista en la base de datos
    // Incluyendo fecha de nacimiento, género y foto_perfil (si existe)
    const result = await query(
      `INSERT INTO contratistas (nombre, apellido, username, email, fecha_nacimiento, genero, telefono, password, foto_perfil, created_at)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, CURRENT_TIMESTAMP)
       RETURNING nombre, apellido, username, email, fecha_nacimiento, genero, telefono, created_at`,
      [nombre, apellido, finalUser, email, fechaFormateada, genero, telefono, hashedPassword, fotoBase64 || null]
    );

    res.status(201).json({
      success: true,
      message: 'Contratista registrado exitosamente',
      data: result.rows[0],
    });
  } catch (error) {
    handleDatabaseError(error, res, 'Error al registrar contratista');
  }
};

/**
 * Registra un nuevo trabajador
 */
export const registerTrabajador = async (req, res) => {
  try {
    const { nombre, apellido, fechaNacimiento, email, genero, telefono, experiencia, categoria, password, fotoBase64 } = req.body;

    // Validar campos requeridos
    if (!nombre || !apellido || !fechaNacimiento || !email || !telefono || !experiencia || !categoria || !password) {
      return handleValidationError(res, 'Todos los campos son requeridos');
    }

    // Extraer el user del email
    const user = extractUsernameFromEmail(email);
    
    // Convertir fecha de formato DD/MM/YYYY a YYYY-MM-DD
    const fechaFormateada = convertDateFormat(fechaNacimiento);

    // Verificar si el email ya existe
    const emailCheck = await query(
      'SELECT email FROM trabajadores WHERE email = $1',
      [email]
    );

    if (emailCheck.rows.length > 0) {
      return handleValidationError(res, 'El email ya está registrado', 409);
    }

    // Verificar si el username ya existe
    const userCheck = await query(
      'SELECT username FROM trabajadores WHERE username = $1',
      [user]
    );

    let finalUser = user;

    if (userCheck.rows.length > 0) {
      // Si el username ya existe, añadir un número al final
      let counter = 1;
      let uniqueUser = `${user}${counter}`;
      
      while (true) {
        const check = await query(
          'SELECT username FROM trabajadores WHERE username = $1',
          [uniqueUser]
        );
        
        if (check.rows.length === 0) {
          break;
        }
        counter++;
        uniqueUser = `${user}${counter}`;
      }
      
      finalUser = uniqueUser;
    }

    // Obtener el id_categoria basado en el nombre de la categoría
    // Primero verificamos si existe la categoría
    let categoriaId;
    const categoriaCheck = await query(
      'SELECT id_categoria FROM categorias WHERE nombre = $1',
      [categoria]
    );

    if (categoriaCheck.rows.length === 0) {
      // Si no existe, crear la categoría
      const newCategoria = await query(
        'INSERT INTO categorias (nombre) VALUES ($1) RETURNING id_categoria',
        [categoria]
      );
      categoriaId = newCategoria.rows[0].id_categoria;
    } else {
      categoriaId = categoriaCheck.rows[0].id_categoria;
    }

    // Encriptar la contraseña antes de guardarla
    const hashedPassword = await hashPassword(password);

    // Insertar trabajador en la base de datos
    // Incluyendo fecha_nacimiento, género, experiencia y foto_perfil (si existe)
    const result = await query(
      `INSERT INTO trabajadores (nombre, apellido, username, email, fecha_nacimiento, genero, telefono, password, categoria, experiencia, disponible, calificacion_promedio, foto_perfil, created_at)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, CURRENT_TIMESTAMP)
       RETURNING nombre, apellido, username, email, fecha_nacimiento, genero, telefono, experiencia, categoria, created_at`,
      [nombre, apellido, finalUser, email, fechaFormateada, genero, telefono, hashedPassword, categoriaId, experiencia, true, 0.0, fotoBase64 || null]
    );

    // Obtener el nombre de la categoría para devolverlo en la respuesta
    const categoriaResult = await query(
      'SELECT nombre FROM categorias WHERE id_categoria = $1',
      [categoriaId]
    );

    const responseData = {
      ...result.rows[0],
      categoria: categoriaResult.rows[0]?.nombre || categoria,
    };

    res.status(201).json({
      success: true,
      message: 'Trabajador registrado exitosamente',
      data: responseData,
    });
  } catch (error) {
    handleDatabaseError(error, res, 'Error al registrar trabajador');
  }
};

