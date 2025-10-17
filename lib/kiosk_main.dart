import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/customer_checkin_screen.dart';
import 'auth/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    print('Firebase initialization error: $e');
  }

  runApp(const CheckinKioskApp());
}

class CheckinKioskApp extends StatelessWidget {
  const CheckinKioskApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CatEye POS - Customer Check-in Kiosk',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
        // Make text larger for kiosk usage
        textTheme: Theme.of(context).textTheme.apply(fontSizeFactor: 1.1),
        // Make buttons larger for touch
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(120, 48),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          ),
        ),
      ),
      home: const KioskHomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class KioskHomeScreen extends StatelessWidget {
  const KioskHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade700, Colors.blue.shade500],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: isTablet ? 800 : 400,
                maxHeight: screenSize.height * 0.8,
              ),
              margin: const EdgeInsets.all(32),
              child: Card(
                elevation: 16,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Padding(
                  padding: EdgeInsets.all(isTablet ? 64 : 48),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo/Icon
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.blue.shade200,
                            width: 3,
                          ),
                        ),
                        child: Icon(
                          Icons.store,
                          size: isTablet ? 100 : 80,
                          color: Colors.blue.shade700,
                        ),
                      ),
                      SizedBox(height: isTablet ? 48 : 32),

                      // Welcome text
                      Text(
                        'Welcome to',
                        style: TextStyle(
                          fontSize: isTablet ? 28 : 22,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'CatEye POS',
                        style: TextStyle(
                          fontSize: isTablet ? 48 : 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade800,
                        ),
                      ),
                      SizedBox(height: isTablet ? 16 : 12),
                      Text(
                        'Customer Check-in Kiosk',
                        style: TextStyle(
                          fontSize: isTablet ? 20 : 16,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: isTablet ? 64 : 48),

                      // Check-in button
                      SizedBox(
                        width: double.infinity,
                        height: isTablet ? 80 : 64,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const CustomerCheckinScreen(),
                              ),
                            );
                          },
                          icon: Icon(Icons.touch_app, size: isTablet ? 32 : 24),
                          label: Text(
                            'Touch to Check In',
                            style: TextStyle(
                              fontSize: isTablet ? 24 : 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade600,
                            foregroundColor: Colors.white,
                            elevation: 8,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: isTablet ? 32 : 24),

                      // Instructions
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Colors.blue.shade600,
                              size: isTablet ? 24 : 20,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'New customers: We\'ll create your account\nReturning customers: Just enter your phone number',
                              style: TextStyle(
                                fontSize: isTablet ? 16 : 14,
                                color: Colors.grey.shade700,
                                height: 1.4,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),

                      // Footer
                      SizedBox(height: isTablet ? 32 : 24),
                      Text(
                        'Please ensure your hands are clean before using the touchscreen',
                        style: TextStyle(
                          fontSize: isTablet ? 12 : 10,
                          color: Colors.grey.shade500,
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
