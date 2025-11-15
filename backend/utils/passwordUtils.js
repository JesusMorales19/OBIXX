import bcrypt from 'bcrypt';

/**
 * Hashea una contraseña usando bcrypt
 * @param {string} password - Contraseña en texto plano
 * @returns {Promise<string>} - Contraseña hasheada
 */
export const hashPassword = async (password) => {
  try {
    const saltRounds = 10; // Número de rondas de sal (10 es un buen balance entre seguridad y velocidad)
    const hashedPassword = await bcrypt.hash(password, saltRounds);
    return hashedPassword;
  } catch (error) {
    console.error('Error al hashear contraseña:', error);
    throw new Error('Error al encriptar la contraseña');
  }
};

/**
 * Compara una contraseña en texto plano con una contraseña hasheada
 * @param {string} password - Contraseña en texto plano
 * @param {string} hashedPassword - Contraseña hasheada
 * @returns {Promise<boolean>} - true si coinciden, false si no
 */
export const comparePassword = async (password, hashedPassword) => {
  try {
    const isMatch = await bcrypt.compare(password, hashedPassword);
    return isMatch;
  } catch (error) {
    console.error('Error al comparar contraseñas:', error);
    return false;
  }
};

