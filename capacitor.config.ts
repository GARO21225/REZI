import { CapacitorConfig } from '@capacitor/cli';

const config: CapacitorConfig = {
  appId: 'ci.pcr.ouloger',
  appName: 'PCR ou Loger',
  webDir: 'frontend',
  server: {
    androidScheme: 'https',
    // En développement, pointer vers le serveur local :
    // url: 'http://192.168.1.x:3000',
    // cleartext: true
  },
  plugins: {
    SplashScreen: {
      launchShowDuration: 2500,
      launchAutoHide: true,
      backgroundColor: '#0b0f1a',
      androidSplashResourceName: 'splash',
      androidScaleType: 'CENTER_CROP',
      showSpinner: false,
      splashFullScreen: true,
      splashImmersive: true,
    },
    StatusBar: {
      style: 'Dark',
      backgroundColor: '#0b0f1a',
    },
    Geolocation: {
      // Permissions déclarées dans AndroidManifest.xml et Info.plist
    },
    PushNotifications: {
      presentationOptions: ['badge', 'sound', 'alert'],
    },
  },
  android: {
    buildOptions: {
      keystorePath: 'pcr-ouloger-release.keystore',
      keystoreAlias: 'pcr-ouloger',
    },
    allowMixedContent: false,
    captureInput: true,
    webContentsDebuggingEnabled: false,
  },
  ios: {
    contentInset: 'automatic',
    scrollEnabled: true,
    limitsNavigationsToAppBoundDomains: true,
  },
};

export default config;
