import os from 'os';

/**
 * Obtiene la IP local de la máquina en la red
 */
export const getLocalIp = () => {
  const interfaces = os.networkInterfaces();
  
  for (const name of Object.keys(interfaces)) {
    for (const iface of interfaces[name]) {
      // Ignorar direcciones internas y no IPv4
      if (iface.family === 'IPv4' && !iface.internal) {
        // Preferir direcciones que no sean de loopback
        if (!iface.address.startsWith('127.')) {
          return iface.address;
        }
      }
    }
  }
  
  // Si no encuentra ninguna, devolver null
  return null;
};

/**
 * Obtiene todas las IPs locales de la máquina
 */
export const getAllLocalIps = () => {
  const interfaces = os.networkInterfaces();
  const ips = [];
  
  for (const name of Object.keys(interfaces)) {
    for (const iface of interfaces[name]) {
      if (iface.family === 'IPv4' && !iface.internal) {
        if (!iface.address.startsWith('127.')) {
          ips.push({
            interface: name,
            address: iface.address,
          });
        }
      }
    }
  }
  
  return ips;
};

