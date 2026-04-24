import * as admin from 'firebase-admin';

// Initialize Firebase Admin SDK
const initializeFirebaseAdmin = () => {
  if (!admin.apps.length) {
    // Validate required environment variables
    const requiredEnvVars = [
      'FIREBASE_PROJECT_ID',
      'FIREBASE_PRIVATE_KEY_ID',
      'FIREBASE_PRIVATE_KEY',
      'FIREBASE_CLIENT_EMAIL',
      'FIREBASE_CLIENT_ID',
      'FIREBASE_CLIENT_X509_CERT_URL'
    ];

    const missingVars = requiredEnvVars.filter(varName => !process.env[varName]);
    if (missingVars.length > 0) {
      throw new Error(`Missing required Firebase environment variables: ${missingVars.join(', ')}`);
    }

    // In production, use service account key from environment variable
    // For development, you can use the Firebase config from .env
    const serviceAccount = {
      type: "service_account",
      project_id: process.env.FIREBASE_PROJECT_ID!,
      private_key_id: process.env.FIREBASE_PRIVATE_KEY_ID!,
      private_key: process.env.FIREBASE_PRIVATE_KEY!.replace(/\\n/g, '\n'),
      client_email: process.env.FIREBASE_CLIENT_EMAIL!,
      client_id: process.env.FIREBASE_CLIENT_ID!,
      auth_uri: "https://accounts.google.com/o/oauth2/auth",
      token_uri: "https://oauth2.googleapis.com/token",
      auth_provider_x509_cert_url: "https://www.googleapis.com/oauth2/v1/certs",
      client_x509_cert_url: process.env.FIREBASE_CLIENT_X509_CERT_URL!
    };

    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount as admin.ServiceAccount),
      projectId: process.env.FIREBASE_PROJECT_ID!
    });
  }
  return admin;
};

export const firebaseAdmin = initializeFirebaseAdmin();

// Firebase authentication middleware
export const authenticateFirebaseToken = async (req: any, res: any, next: any) => {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({
        success: false,
        error: 'Authorization token required'
      });
    }

    const token = authHeader.substring(7); // Remove 'Bearer ' prefix

    // Verify Firebase token
    const decodedToken = await firebaseAdmin.auth().verifyIdToken(token);
    const signInProvider = decodedToken.firebase?.sign_in_provider;

    // Production guard: require verified email for password-based authentication.
    if (signInProvider === 'password' && !decodedToken.email_verified) {
      return res.status(403).json({
        success: false,
        error: 'Email not verified. Please verify your email before continuing.'
      });
    }

    // Attach user info to request
    req.user = {
      uid: decodedToken.uid,
      email: decodedToken.email,
      emailVerified: decodedToken.email_verified,
      signInProvider,
      name: decodedToken.name,
      picture: decodedToken.picture,
      firebaseToken: token
    };

    next();
  } catch (error) {
    console.error('Firebase token verification failed:', error);
    return res.status(401).json({
      success: false,
      error: 'Invalid or expired token'
    });
  }
};

// Helper function to get Firebase user by UID
export const getFirebaseUser = async (uid: string): Promise<admin.auth.UserRecord> => {
  try {
    return await firebaseAdmin.auth().getUser(uid);
  } catch (error) {
    console.error('Error getting Firebase user:', error);
    throw error;
  }
};

// Helper function to create custom claims for user roles
export const setUserRole = async (uid: string, role: string) => {
  try {
    await firebaseAdmin.auth().setCustomUserClaims(uid, { role });
  } catch (error) {
    console.error('Error setting user role:', error);
    throw error;
  }
};

export default firebaseAdmin;
