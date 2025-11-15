/**
 * Extrae el nombre de usuario del email
 * Ejemplo: jesuhernan232@gmail.com -> jesuhernan232
 */
export const extractUsernameFromEmail = (email) => {
  if (!email || typeof email !== 'string') {
    return '';
  }
  
  // Dividir por @ y tomar la primera parte
  const parts = email.split('@');
  if (parts.length > 0) {
    return parts[0];
  }
  
  return '';
};

/**
 * Convierte fecha de formato DD/MM/YYYY a YYYY-MM-DD para PostgreSQL
 */
export const convertDateFormat = (dateString) => {
  if (!dateString) return null;
  
  // Si ya está en formato YYYY-MM-DD, devolverlo tal cual
  if (/^\d{4}-\d{2}-\d{2}$/.test(dateString)) {
    return dateString;
  }
  
  // Si está en formato DD/MM/YYYY, convertirlo
  if (/^\d{2}\/\d{2}\/\d{4}$/.test(dateString)) {
    const [day, month, year] = dateString.split('/');
    return `${year}-${month}-${day}`;
  }
  
  return dateString;
};











