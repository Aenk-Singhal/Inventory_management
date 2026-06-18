import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:inventory_management_system/main.dart';
import 'package:inventory_management_system/screens/Dashboard.dart';
import 'package:inventory_management_system/services/registration_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Auth extends StatefulWidget {
  const Auth({super.key});

  @override
  State<Auth> createState() => _AuthState();
}

class _AuthState extends State<Auth> {
  bool _isSigningIn = false;

  @override
  void initState() {
    super.initState();
    _showRevocationMessageIfNeeded();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _resumeSessionIfNeeded();
    });
  }

  Future<void> _resumeSessionIfNeeded() async {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email;
    if (email == null) return;

    await _handleSignedInUser(email);
                  onPressed: _isSigningIn ? null : _signInWithGoogle,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    side: const BorderSide(color: Colors.white),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  icon: Image.asset(
                    'assets/images/google.png',
                    height: screenSize.height * 0.03, // responsive height
                  ),
                  label: Text(
                    _isSigningIn ? 'Signing in...' : 'Sign in with Google',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: screenSize.width * 0.045,
                    ),
                  ),
                ),
                if (_isSigningIn)
                  const Padding(
                    padding: EdgeInsets.only(top: 16),
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  Future<void> _signInWithGoogle() async {
    setState(() {
      _isSigningIn = true;
    });

    try {
      final isLogged = await login();
      if (!mounted) return;

      if (!isLogged) {
        _showSnackBar('Sign in was cancelled or failed. Please try again.', Colors.red);
        return;
      }

      final email = FirebaseAuth.instance.currentUser?.email;
      if (email == null) {
        _showSnackBar('Could not read your Google account email.', Colors.red);
        return;
      }

      await _handleSignedInUser(email);
    } finally {
      if (mounted) {
        setState(() {
          _isSigningIn = false;
        });
      }
    }
  }

  Future<void> _handleSignedInUser(String email) async {
    final needsInviteCode = await _needsInviteCode(email);
    if (!mounted) return;

    if (needsInviteCode) {
      _showInviteCodeDialog(email);
      return;
    }

    _goToDashboard();
  }

  void _goToDashboard() {
    final navigator = navigatorKey.currentState;
    if (navigator == null) {
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const Dashboard()),
        (_) => false,
      );
      return;
    }

    navigator.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const Dashboard()),
      (_) => false,
    );
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
  Future<bool> login() async {
    try {
      final user = await GoogleSignIn().signIn();

      if (user == null) {
        return false;
      }

      final userAuth = await user.authentication;

      final credential = GoogleAuthProvider.credential(
        idToken: userAuth.idToken,
        accessToken: userAuth.accessToken,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);

      return FirebaseAuth.instance.currentUser != null;
    } catch (e) {
      debugPrint('Login error: $e');
      return false;
    }
  }

  Future<bool> _needsInviteCode(String email) async {
    try {
      final userDoc = await RegistrationService.getUserDoc(email);

      if (!userDoc.exists) return true;

      if (!RegistrationService.isRegistered(userDoc)) {
        await RegistrationService.forceLogout();
        if (mounted) {
          _showSnackBar('Your account has been deactivated.', Colors.red);
        }
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('Error checking invite code requirement: $e');
      if (mounted) {
        _showSnackBar('Could not verify your account. Please try again.', Colors.red);
      }
      return true;
    }
  }

  void _showInviteCodeDialog(String email) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return InviteCodeDialog(
          email: RegistrationService.normalizeEmail(email),
          onSuccess: () {
            Navigator.of(dialogContext).pop();
            _goToDashboard();
          },
          onCancel: () {
            Navigator.of(dialogContext).pop();
            FirebaseAuth.instance.signOut();
            GoogleSignIn().signOut();
          },
        );
      },
    );
  }
}

// Invite Code Dialog Widget
class InviteCodeDialog extends StatefulWidget {
  final String email;
  final VoidCallback onSuccess;
  final VoidCallback onCancel;

  const InviteCodeDialog({
    Key? key,
    required this.email,
    required this.onSuccess,
    required this.onCancel,
  }) : super(key: key);

  @override
  State<InviteCodeDialog> createState() => _InviteCodeDialogState();
}

class _InviteCodeDialogState extends State<InviteCodeDialog> {
  final TextEditingController _codeController = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return AlertDialog(
      backgroundColor: const Color(0xFF2E2E2E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Column(
        children: [
          const Icon(
            Icons.mail_outline,
            size: 48,
            color: Colors.blue,
          ),
          const SizedBox(height: 16),
          const Text(
            'Invite Code Required',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Please enter the invite code sent to:',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            widget.email,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _codeController,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              letterSpacing: 2,
              fontWeight: FontWeight.bold,
            ),
            decoration: InputDecoration(
              hintText: 'Enter 6-digit code',
              hintStyle: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
              filled: true,
              fillColor: const Color(0xFF1E1E1E),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            maxLength: 6,
            textCapitalization: TextCapitalization.characters,
            keyboardType: TextInputType.text,
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.only(top: 16),
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : widget.onCancel,
          child: const Text(
            'Cancel',
            style: TextStyle(color: Colors.grey),
          ),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _verifyCode,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text('Verify'),
        ),
      ],
    );
  }

  Future<void> _verifyCode() async {
    if (_codeController.text.trim().isEmpty) {
      _showSnackBar('Please enter the invite code', Colors.red);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Find matching invitation
      QuerySnapshot inviteQuery = await FirebaseFirestore.instance
          .collection('pending_invitations')
          .where('email', isEqualTo: widget.email)
          .where('invite_code', isEqualTo: _codeController.text.trim().toUpperCase())
          .where('expires_at', isGreaterThan: Timestamp.now())
          .get();

      if (inviteQuery.docs.isEmpty) {
        _showSnackBar('Invalid or expired invite code', Colors.red);
        setState(() {
          _isLoading = false;
        });
        return;
      }

      DocumentSnapshot inviteDoc = inviteQuery.docs.first;
      Map<String, dynamic> inviteData = inviteDoc.data() as Map<String, dynamic>;

      // Delete invitation after successful verification
      await inviteDoc.reference.delete();

      // Register user
      await RegistrationService.userDocRef(widget.email).set({
        'email': widget.email,
        'registered_at': FieldValue.serverTimestamp(),
        'invited_by': inviteData['invited_by'],
        'invite_code_used': _codeController.text.trim().toUpperCase(),
        'is_active': true,
      });

      _showSnackBar('Welcome! Registration successful', Colors.green);

      // Small delay to show success message
      await Future.delayed(const Duration(seconds: 1));

      widget.onSuccess();

    } catch (e) {
      print('Error verifying invite code: $e');
      _showSnackBar('Error verifying code. Please try again.', Colors.red);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }
}
