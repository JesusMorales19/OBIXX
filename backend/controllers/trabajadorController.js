import bcrypt from 'bcrypt';
import { query, getClient } from '../config/db.js';
import { handleDatabaseError, handleValidationError, handleError } from '../services/errorHandler.js';

let cascadeConstraintsEnsured = false;

const ensureCascadeConstraints = async () => {
  if (cascadeConstraintsEnsured) {
    return;
  }

  const statements = [
    `ALTER TABLE favoritos DROP CONSTRAINT IF EXISTS fk_trabajador`,
    `ALTER TABLE favoritos ADD CONSTRAINT fk_trabajador FOREIGN KEY (email_trabajador) REFERENCES trabajadores(email) ON DELETE CASCADE ON UPDATE CASCADE`,

    `ALTER TABLE asignaciones_trabajo DROP CONSTRAINT IF EXISTS fk_asignacion_trabajador`,
    `ALTER TABLE asignaciones_trabajo ADD CONSTRAINT fk_asignacion_trabajador FOREIGN KEY (email_trabajador) REFERENCES trabajadores(email) ON DELETE CASCADE ON UPDATE CASCADE`,

    `ALTER TABLE calificaciones_trabajadores DROP CONSTRAINT IF EXISTS fk_calificacion_trabajador`,
    `ALTER TABLE calificaciones_trabajadores ADD CONSTRAINT fk_calificacion_trabajador FOREIGN KEY (email_trabajador) REFERENCES trabajadores(email) ON DELETE CASCADE ON UPDATE CASCADE`,

    `ALTER TABLE trabajadores ADD COLUMN IF NOT EXISTS descripcion TEXT`,
  ];

  for (const statement of statements) {
    await query(statement);
  }

  cascadeConstraintsEnsured = true;
};

export const obtenerPerfilTrabajador = async (req, res) => {
  try {
    const { email } = req.query;

    if (!email) {
      return handleValidationError(res, 'El email del trabajador es requerido');
    }

    const result = await query(
      `SELECT 
         nombre,
         apellido,
         username,
         email,
         telefono,
         fecha_nacimiento,
         genero,
         categoria,
         experiencia,
         foto_perfil,
         calificacion_promedio,
         created_at,
         descripcion
       FROM trabajadores
       WHERE email = $1
       LIMIT 1`,
      [email]
    );

    if (result.rows.length === 0) {
      return handleValidationError(res, 'Trabajador no encontrado', 404);
    }

    return res.status(200).json({
      success: true,
      data: result.rows[0],
    });
  } catch (error) {
    handleDatabaseError(error, res, 'Error al obtener perfil del trabajador');
  }
};

export const actualizarPerfilTrabajador = async (req, res) => {
  const {
    emailActual,
    nuevoEmail,
    telefono,
    descripcion,
    fotoPerfilBase64,
    passwordActual,
    passwordNueva,
  } = req.body;

  if (
    !emailActual ||
    typeof emailActual !== 'string' ||
    emailActual.trim().length === 0
  ) {
    return handleValidationError(res, 'El email actual es requerido');
  }

  if (
    nuevoEmail === undefined &&
    telefono === undefined &&
    descripcion === undefined &&
    fotoPerfilBase64 === undefined &&
    passwordNueva === undefined
  ) {
    return handleValidationError(res, 'No se proporcionaron cambios para realizar');
  }

  const emailActualLimpio = emailActual.trim();
  const emailActualLower = emailActualLimpio.toLowerCase();
  const EMAIL_REGEX = /^[\w.-]+@[\w-]+\.[A-Za-z]{2,}$/;
  const PHONE_REGEX = /^[0-9]{10}$/;

  let nuevoEmailLimpio;
  if (nuevoEmail !== undefined) {
    if (typeof nuevoEmail !== 'string') {
      return handleValidationError(res, 'El nuevo email debe ser una cadena válida');
    }
    nuevoEmailLimpio = nuevoEmail.trim().toLowerCase();
    if (!EMAIL_REGEX.test(nuevoEmailLimpio)) {
      return handleValidationError(res, 'El formato del nuevo email no es válido');
    }
  }

  let telefonoLimpio;
  if (telefono !== undefined) {
    telefonoLimpio = String(telefono).trim();
    if (!PHONE_REGEX.test(telefonoLimpio)) {
      return handleValidationError(res, 'El teléfono debe contener solo números (10 dígitos)');
    }
  }

  await ensureCascadeConstraints();
  const client = await getClient();

  try {
    await client.query('BEGIN');

    const perfilResult = await client.query(
      'SELECT email, telefono, username, password FROM trabajadores WHERE email = $1',
      [emailActualLimpio]
    );

    if (perfilResult.rows.length === 0) {
      await client.query('ROLLBACK');
      return handleValidationError(res, 'Trabajador no encontrado', 404);
    }

    let emailDestino = emailActualLimpio;
    let usernameDestino = perfilResult.rows[0].username;

    const usernameExiste = async (username) => {
      const existeTrabajador = await client.query(
        'SELECT email FROM trabajadores WHERE username = $1 AND email <> $2',
        [username, emailActualLimpio]
      );
      if (existeTrabajador.rows.length > 0) {
        return true;
      }
      const existeContratista = await client.query(
        'SELECT email FROM contratistas WHERE username = $1',
        [username]
      );
      return existeContratista.rows.length > 0;
    };

    if (nuevoEmailLimpio && nuevoEmailLimpio !== emailActualLower) {
      const existeTrabajador = await client.query(
        'SELECT email FROM trabajadores WHERE email = $1',
        [nuevoEmailLimpio]
      );

      if (existeTrabajador.rows.length > 0) {
        await client.query('ROLLBACK');
        return handleValidationError(res, 'El nuevo email ya está en uso', 409);
      }

      const existeContratista = await client.query(
        'SELECT email FROM contratistas WHERE email = $1',
        [nuevoEmailLimpio]
      );

      if (existeContratista.rows.length > 0) {
        await client.query('ROLLBACK');
        return handleValidationError(res, 'El nuevo email ya está en uso', 409);
      }

      const baseNueva = nuevoEmailLimpio.split('@')[0];
      let nuevoUsername = baseNueva;
      let suffix = 1;

      while (await usernameExiste(nuevoUsername)) {
        nuevoUsername = `${baseNueva}${suffix}`;
        suffix++;
      }

      usernameDestino = nuevoUsername;

      await client.query(
        'UPDATE trabajadores SET email = $1, username = $2 WHERE email = $3',
        [nuevoEmailLimpio, usernameDestino, emailActualLimpio]
      );

      emailDestino = nuevoEmailLimpio;
    }

    if (telefonoLimpio !== undefined) {
      await client.query(
        'UPDATE trabajadores SET telefono = $1 WHERE email = $2',
        [telefonoLimpio, emailDestino]
      );
    }

    if (descripcion !== undefined) {
      await client.query(
        'UPDATE trabajadores SET descripcion = $1 WHERE email = $2',
        [descripcion, emailDestino]
      );
    }

    if (fotoPerfilBase64 !== undefined) {
      await client.query(
        'UPDATE trabajadores SET foto_perfil = $1 WHERE email = $2',
        [fotoPerfilBase64, emailDestino]
      );
    }

    if (passwordNueva !== undefined) {
      if (!passwordActual) {
        await client.query('ROLLBACK');
        return handleValidationError(res, 'Debe proporcionar la contraseña actual');
      }

      const hashActual = perfilResult.rows[0].password;
      const coincide = await bcrypt.compare(passwordActual, hashActual);

      if (!coincide) {
        await client.query('ROLLBACK');
        return handleValidationError(res, 'La contraseña actual es incorrecta');
      }

      if (passwordNueva.length < 6) {
        await client.query('ROLLBACK');
        return handleValidationError(res, 'La nueva contraseña debe tener al menos 6 caracteres');
      }

      const nuevoHash = await bcrypt.hash(passwordNueva, 10);
      await client.query(
        'UPDATE trabajadores SET password = $1 WHERE email = $2',
        [nuevoHash, emailDestino]
      );
    }

    await client.query('COMMIT');

    const perfilActualizado = await query(
      `SELECT 
         nombre,
         apellido,
         username,
         email,
         telefono,
         fecha_nacimiento,
         genero,
         categoria,
         experiencia,
         foto_perfil,
         calificacion_promedio,
         created_at,
         descripcion
       FROM trabajadores
       WHERE email = $1
       LIMIT 1`,
      [emailDestino]
    );

    return res.status(200).json({
      success: true,
      data: perfilActualizado.rows[0],
    });
  } catch (error) {
    await client.query('ROLLBACK').catch(() => {});
    handleDatabaseError(error, res, 'Error al actualizar perfil del trabajador');
  } finally {
    client.release();
  }
};

