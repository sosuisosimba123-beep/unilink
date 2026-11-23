import 'package:flutter/material.dart';
import '../../theme.dart';
import '../../services/pocketbase_repository.dart';
import '../../services/pocketbase_service.dart';
import '../../models/programme_model.dart';
import '../../main.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _regNoController = TextEditingController();
  
  String _selectedRole = 'student';
  bool _isLoading = false;
  bool _isLoadingProgrammes = true;
  String? _errorMessage;

  List<ProgrammeModel> _programmes = [];
  ProgrammeModel? _selectedProgramme;
  int _selectedYear = 1;

  @override
  void initState() {
    super.initState();
    _loadProgrammes();
  }

  Future<void> _loadProgrammes() async {
    await pbRepository.seedDefaultData();
    final progs = await pbRepository.getProgrammes();
    if (mounted) {
      setState(() {
        _programmes = progs;
        if (progs.isNotEmpty) {
          _selectedProgramme = progs.first;
          _selectedYear = 1;
        }
        _isLoadingProgrammes = false;
      });
    }
  }

  Future<void> _handleRegister() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();
      final name = _nameController.text.trim();
      final regNo = _regNoController.text.trim();

      if (_selectedRole == 'student') {
        if (regNo.isEmpty) {
          setState(() {
            _errorMessage = 'Registration number is required for students.';
            _isLoading = false;
          });
          return;
        }
        if (_selectedProgramme == null) {
          setState(() {
            _errorMessage = 'Please select a valid academic programme.';
            _isLoading = false;
          });
          return;
        }

        // Use auto-enrollment registration method
        final user = await pbRepository.registerStudentWithAutoEnrollment(
          name: name,
          email: email,
          password: password,
          registrationNumber: regNo,
          programmeCode: _selectedProgramme!.code,
          year: _selectedYear,
        );

        if (user == null) {
          throw Exception('Student registration and course auto-enrollment failed.');
        }
      } else {
        // Lecturer registration
        await pocketBaseService.pb.collection('users').create(body: {
          'email': email,
          'password': password,
          'passwordConfirm': password,
          'name': name,
          'role': 'lecturer',
          'registration_number': 'N/A',
          'is_on_campus': true,
        });
        await pocketBaseService.login(email, password);
      }

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const MainShell()),
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'Registration failed. Email may already be in use or password is too short (min 8 chars).';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    int maxYears = _selectedProgramme?.years ?? 3;
    List<int> yearList = List.generate(maxYears > 0 ? maxYears : 3, (i) => i + 1);
    if (!yearList.contains(_selectedYear)) {
      _selectedYear = 1;
    }

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.primaryContainer],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 480),
                padding: const EdgeInsets.all(32.0),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.primaryContainer.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.person_add, size: 36, color: AppColors.primary),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Register Now',
                          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Join Moshi Cooperative University (MoCU) Portal',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.amber.shade300),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, color: Colors.amber.shade800, size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              '⚠️ WARNING: Providing false identification numbers or proxy registration during attendance check-ins is a severe academic offense under MoCU regulations and will result in disciplinary action or loss of exam eligibility.',
                              style: TextStyle(color: Colors.amber.shade900, fontSize: 11, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (_errorMessage != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: Colors.red.shade800, fontSize: 13),
                        ),
                      ),
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        prefixIcon: Icon(Icons.badge_outlined),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'University Email',
                        hintText: 'e.g. student@mocu.ac.tz',
                        prefixIcon: Icon(Icons.email_outlined),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Password (min 8 characters)',
                        prefixIcon: Icon(Icons.lock_outline),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedRole,
                      items: const [
                        DropdownMenuItem(value: 'student', child: Text('Student')),
                        DropdownMenuItem(value: 'lecturer', child: Text('Lecturer')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedRole = val);
                      },
                      decoration: const InputDecoration(
                        labelText: 'Account Role',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.work_outline),
                      ),
                    ),
                    if (_selectedRole == 'student') ...[
                      const SizedBox(height: 16),
                      TextField(
                        controller: _regNoController,
                        decoration: const InputDecoration(
                          labelText: 'Registration Number',
                          hintText: 'e.g. CIT/2024/0012',
                          prefixIcon: Icon(Icons.pin_outlined),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _isLoadingProgrammes
                          ? const Center(child: CircularProgressIndicator())
                          : DropdownButtonFormField<ProgrammeModel>(
                              value: _selectedProgramme,
                              isExpanded: true,
                              items: _programmes
                                  .map((prog) => DropdownMenuItem(
                                        value: prog,
                                        child: Text('${prog.code} - ${prog.name}', overflow: TextOverflow.ellipsis),
                                      ))
                                  .toList(),
                              onChanged: (prog) {
                                if (prog != null) {
                                  setState(() {
                                    _selectedProgramme = prog;
                                    _selectedYear = 1;
                                  });
                                }
                              },
                              decoration: const InputDecoration(
                                labelText: 'Academic Programme',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.school_outlined),
                              ),
                            ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<int>(
                        value: _selectedYear,
                        isExpanded: true,
                        items: yearList
                            .map((yr) => DropdownMenuItem(
                                  value: yr,
                                  child: Text('Year $yr'),
                                ))
                            .toList(),
                        onChanged: (yr) {
                          if (yr != null) {
                            setState(() {
                              _selectedYear = yr;
                            });
                          }
                        },
                        decoration: const InputDecoration(
                          labelText: 'Academic Year / Level',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.calendar_today_outlined),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _handleRegister,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Create Account & Auto-Enroll', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text('Already have an account? Sign In'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
