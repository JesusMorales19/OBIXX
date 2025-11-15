import { query, getClient } from '../config/db.js';
import bcrypt from 'bcrypt';
import { handleDatabaseError, handleValidationError, handleError } from '../services/errorHandler.js';

let cascadeConstraintsEnsured = false;

const ensureCascadeConstraints = async () => {
  if (cascadeConstraintsEnsured) {
    return;
  }

  const statements = [
    `ALTER TABLE favoritos DROP CONSTRAINT IF EXISTS fk_contratista`,
    `ALTER TABLE favoritos ADD CONSTRAINT fk_contratista FOREIGN KEY (email_contratista) REFERENCES contratistas(email) ON DELETE CASCADE ON UPDATE CASCADE`,

    `ALTER TABLE asignaciones_trabajo DROP CONSTRAINT IF EXISTS fk_asignacion_contratista`,
    `ALTER TABLE asignaciones_trabajo ADD CONSTRAINT fk_asignacion_contratista FOREIGN KEY (email_contratista) REFERENCES contratistas(email) ON DELETE CASCADE ON UPDATE CASCADE`,

    `ALTER TABLE calificaciones_trabajadores DROP CONSTRAINT IF EXISTS fk_calificacion_contratista`,
    `ALTER TABLE calificaciones_trabajadores ADD CONSTRAINT fk_calificacion_contratista FOREIGN KEY (email_contratista) REFERENCES contratistas(email) ON DELETE CASCADE ON UPDATE CASCADE`,

    `ALTER TABLE trabajos_largo_plazo DROP CONSTRAINT IF EXISTS fk_trabajos_largo_contratista`,
    `ALTER TABLE trabajos_largo_plazo ADD CONSTRAINT fk_trabajos_largo_contratista FOREIGN KEY (email_contratista) REFERENCES contratistas(email) ON DELETE CASCADE ON UPDATE CASCADE`,

    `ALTER TABLE trabajos_corto_plazo DROP CONSTRAINT IF EXISTS fk_tc_contratista`,
    `ALTER TABLE trabajos_corto_plazo ADD CONSTRAINT fk_tc_contratista FOREIGN KEY (email_contratista) REFERENCES contratistas(email) ON DELETE CASCADE ON UPDATE CASCADE`,
  ];

  for (const statement of statements) {
    await query(statement);
  }

  cascadeConstraintsEnsured = true;
};

export const obtenerPerfilContratista = async (req, res) => {
  try {
    const { email } = req.query;

    if (!email) {
      return handleValidationError(res, 'El email del contratista es requerido');
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
        foto_perfil,
        created_at,
        latitud,
        longitud
       FROM contratistas
       WHERE email = $1
       LIMIT 1`,
      [email]
    );

    if (result.rows.length === 0) {
      return handleValidationError(res, 'Contratista no encontrado', 404);
    }

    return res.json({
      success: true,
      data: result.rows[0],
    });
  } catch (error) {
    handleDatabaseError(error, res, 'Error al obtener perfil del contratista');
  }
};

export const actualizarPerfilContratista = async (req, res) => {
  const {
    emailActual,
    nuevoEmail,
    telefono,
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
      'SELECT email, telefono, username, password FROM contratistas WHERE email = $1',
      [emailActualLimpio]
    );

    if (perfilResult.rows.length === 0) {
      await client.query('ROLLBACK');
      return handleValidationError(res, 'Contratista no encontrado', 404);
    }

    let emailDestino = emailActualLimpio;
    let usernameDestino = perfilResult.rows[0].username;

    if (nuevoEmailLimpio && nuevoEmailLimpio !== emailActualLower) {
      const existe = await client.query(
        'SELECT email FROM contratistas WHERE email = $1',
        [nuevoEmailLimpio]
      );

      if (existe.rows.length > 0) {
        await client.query('ROLLBACK');
        return handleValidationError(res, 'El nuevo email ya está en uso', 409);
      }

      const baseNueva = nuevoEmailLimpio.split('@')[0];
      let nuevoUsername = baseNueva;
      let suffix = 1;

      const usernameExiste = async (username) => {
        const existeContratista = await client.query(
          'SELECT email FROM contratistas WHERE username = $1 AND email <> $2',
          [username, emailActualLimpio]
        );
        if (existeContratista.rows.length > 0) {
          return true;
        }
        const existeTrabajador = await client.query(
          'SELECT email FROM trabajadores WHERE username = $1',
          [username]
        );
        return existeTrabajador.rows.length > 0;
      };

      while (await usernameExiste(nuevoUsername)) {
        nuevoUsername = `${baseNueva}${suffix}`;
        suffix++;
      }

      usernameDestino = nuevoUsername;

      await client.query(
        'UPDATE contratistas SET email = $1, username = $2 WHERE email = $3',
        [nuevoEmailLimpio, usernameDestino, emailActualLimpio]
      );

      emailDestino = nuevoEmailLimpio;
    }

    if (telefonoLimpio !== undefined) {
      await client.query(
        'UPDATE contratistas SET telefono = $1 WHERE email = $2',
        [telefonoLimpio, emailDestino]
      );
    }

    if (fotoPerfilBase64 !== undefined) {
      await client.query(
        'UPDATE contratistas SET foto_perfil = $1 WHERE email = $2',
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
        'UPDATE contratistas SET password = $1 WHERE email = $2',
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
         foto_perfil,
         created_at,
         latitud,
         longitud
       FROM contratistas
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
    handleDatabaseError(error, res, 'Error al actualizar perfil del contratista');
  } finally {
    client.release();
  }
};
