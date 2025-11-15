import fs from 'fs';
import path from 'path';
import admin from 'firebase-admin';
import { fileURLToPath } from 'url';
import { config as loadEnv } from 'dotenv';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

loadEnv();

let firebaseAppInitialized = false;

const resolveCredentials = () => {
  const explicitPath = process.env.FIREBASE_CREDENTIALS_PATH;
  const encodedCredentials = process.env.FIREBASE_CREDENTIALS_BASE64;

  if (encodedCredentials) {
    try {
      const jsonString = Buffer.from(encodedCredentials, 'base64').toString('utf8');
      return JSON.parse(jsonString);
    } catch (error) {
      console.error(
        '[Firebase] No se pudieron decodificar las credenciales proporcionadas en FIREBASE_CREDENTIALS_BASE64.',
        error
      );
    }
  }

  if (explicitPath) {
    const absolutePath = path.isAbsolute(explicitPath)
      ? explicitPath
      : path.join(__dirname, '..', explicitPath);

    if (!fs.existsSync(absolutePath)) {
      console.error(`[Firebase] No se encontró el archivo de credenciales en ${absolutePath}`);
      return null;
    }

    try {
      const fileContents = fs.readFileSync(absolutePath, 'utf8');
      return JSON.parse(fileContents);
    } catch (error) {
      console.error(
        '[Firebase] Ocurrió un error al leer el archivo de credenciales especificado.',
        error
      );
      return null;
    }
  }

  const defaultPath = path.join(__dirname, '..', 'firebase-service-account.json');
  if (fs.existsSync(defaultPath)) {
    try {
      const fileContents = fs.readFileSync(defaultPath, 'utf8');
      return JSON.parse(fileContents);
    } catch (error) {
      console.error(
        '[Firebase] Ocurrió un error al leer firebase-service-account.json en la carpeta backend.',
        error
      );
    }
  }

  console.warn(
    '[Firebase] No se encontraron credenciales. Configure FIREBASE_CREDENTIALS_PATH, FIREBASE_CREDENTIALS_BASE64 o coloque firebase-service-account.json en backend/.'
  );
  return null;
};

export const initializeFirebaseApp = () => {
  if (firebaseAppInitialized) {
    return admin.app();
  }

  const credentials = resolveCredentials();

  if (!credentials) {
    console.warn(
      '[Firebase] Se continúa sin inicializar firebase-admin. No se podrán enviar notificaciones push.'
    );
    return null;
  }

  try {
    admin.initializeApp({
      credential: admin.credential.cert(credentials),
    });
    firebaseAppInitialized = true;
    console.info('[Firebase] firebase-admin inicializado correctamente.');
    return admin.app();
  } catch (error) {
    console.error('[Firebase] Error al inicializar firebase-admin:', error);
    return null;
  }
};

export const sendPushNotification = async ({ tokens = [], title, body, data = {}, image }) => {
  if (!firebaseAppInitialized && !initializeFirebaseApp()) {
    return;
  }

  if (!Array.isArray(tokens) || tokens.length === 0) {
    return;
  }

  const message = {
    tokens,
    notification: {
      title,
      body,
    },
    data: Object.entries(data).reduce((acc, [key, value]) => {
      acc[key] = value !== undefined && value !== null ? String(value) : '';
      return acc;
    }, {}),
  };

  if (image) {
    message.notification.image = image;
  }

  try {
    const response = await admin.messaging().sendEachForMulticast(message);
    const failedTokens = [];

    response.responses.forEach((resp, index) => {
      if (!resp.success) {
        const failedToken = tokens[index];
        failedTokens.push({ token: failedToken, error: resp.error?.message });
      }
    });

    if (failedTokens.length > 0) {
      console.warn('[Firebase] Tokens con error al enviar notificaciones:', failedTokens);
    }
  } catch (error) {
    console.error('[Firebase] Error al enviar notificaciones push:', error);
  }
};


