import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'home_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with WidgetsBindingObserver {
  final LocalAuthentication _auth = LocalAuthentication();

  bool _authenticated = false;
  bool _loading = false;
  bool _wasBackgrounded = false;
  String _message = 'Protege tus recuerdos con Face ID';

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _authenticate();
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      if (_authenticated) {
        _wasBackgrounded = true;
      }
    }

    if (state == AppLifecycleState.resumed && _wasBackgrounded) {
      _wasBackgrounded = false;

      Navigator.of(context).popUntil((route) => route.isFirst);

      setState(() {
        _authenticated = false;
        _message = 'Desbloquea Sunset Diary para continuar.';
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _authenticate();
        }
      });
    }
  }

  Future<void> _authenticate() async {
    if (_loading) return;

    setState(() {
      _loading = true;
      _message = 'Verificando identidad...';
    });

    try {
      final supported = await _auth.isDeviceSupported();

      if (!supported) {
        if (mounted) {
          setState(() {
            _message = 'Este dispositivo no admite autenticación local.';
          });
        }
        return;
      }

      final authenticated = await _auth.authenticate(
        localizedReason: 'Desbloquea tus recuerdos de Sunset Diary',
        biometricOnly: false,
        persistAcrossBackgrounding: true,
      );

      if (!mounted) return;

      setState(() {
        _authenticated = authenticated;
        _message = authenticated
            ? 'Acceso autorizado'
            : 'Autenticación cancelada. Intenta nuevamente.';
      });
    } on LocalAuthException catch (e) {
      if (mounted) {
        setState(() {
          if (e.code == LocalAuthExceptionCode.userCanceled ||
              e.code == LocalAuthExceptionCode.systemCanceled) {
            _message = 'Autenticación cancelada. Intenta nuevamente.';
          } else {
            _message = 'No se pudo verificar tu identidad.';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _message = 'Ocurrió un error de autenticación.';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_authenticated) {
      return const HomeScreen();
    }

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(30),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFFFFA45B),
                        Color(0xFFDD6678),
                        Color(0xFF6F488A),
                      ],
                    ),
                  ),
                  child: const Icon(
                    Icons.wb_twilight,
                    size: 75,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 30),
                const Text(
                  'Sunset Diary',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Tus atardeceres, tus recuerdos.',
                  style: TextStyle(color: Colors.white60, fontSize: 16),
                ),
                const SizedBox(height: 35),
                const Icon(
                  Icons.face_unlock_outlined,
                  size: 58,
                  color: Color(0xFFFFA45B),
                ),
                const SizedBox(height: 15),
                Text(
                  _message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 15),
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _loading ? null : _authenticate,
                    icon: _loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.lock_open_outlined),
                    label: Text(
                      _loading ? 'Verificando...' : 'Desbloquear diario',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFA45B),
                      foregroundColor: const Color(0xFF101827),
                      padding: const EdgeInsets.all(18),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
