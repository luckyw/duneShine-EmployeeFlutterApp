import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:employeapplication/constants/colors.dart';

class JobCompletionProofScreen extends StatefulWidget {
  const JobCompletionProofScreen({Key? key}) : super(key: key);

  @override
  State<JobCompletionProofScreen> createState() =>
      _JobCompletionProofScreenState();
}

class _JobCompletionProofScreenState extends State<JobCompletionProofScreen> {
  File? _capturedPhoto;
  final ImagePicker _picker = ImagePicker();
  bool _isPhotoUploaded = false;

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(source: source);
      if (image != null) {
        setState(() {
          _capturedPhoto = File(image.path);
          _isPhotoUploaded = true;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A3A52),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A3A52),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Job Completion Proof',
          style: TextStyle(
            color: AppColors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Text(
                'Please take a clear photo of the clean\ncar as proof of completion.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.white,
                ),
              ),
              const SizedBox(height: 32),
              Container(
                height: 300,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: AppColors.darkNavy,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  color: AppColors.veryLightGray,
                ),
                child: _isPhotoUploaded && _capturedPhoto != null
                    ? GestureDetector(
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            builder: (context) => Container(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ListTile(
                                    leading: const Icon(Icons.camera_alt),
                                    title: const Text('Take Photo'),
                                    onTap: () {
                                      Navigator.pop(context);
                                      _pickImage(ImageSource.camera);
                                    },
                                  ),
                                  ListTile(
                                    leading: const Icon(Icons.image),
                                    title: const Text('Choose from Gallery'),
                                    onTap: () {
                                      Navigator.pop(context);
                                      _pickImage(ImageSource.gallery);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                        child: Container(
                          height: 300,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: AppColors.darkNavy,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Image.file(
                            _capturedPhoto!,
                            fit: BoxFit.cover,
                          ),
                        ),
                      )
                    : GestureDetector(
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            builder: (context) => Container(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ListTile(
                                    leading: const Icon(Icons.camera_alt),
                                    title: const Text('Take Photo'),
                                    onTap: () {
                                      Navigator.pop(context);
                                      _pickImage(ImageSource.camera);
                                    },
                                  ),
                                  ListTile(
                                    leading: const Icon(Icons.image),
                                    title: const Text('Choose from Gallery'),
                                    onTap: () {
                                      Navigator.pop(context);
                                      _pickImage(ImageSource.gallery);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.camera_alt,
                              size: 64,
                              color: AppColors.darkNavy,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Tap to Take Photo',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.darkNavy,
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Skip Photo?'),
                      content:
                          const Text('Please provide a reason for skipping.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.pushNamed(context, '/job-completion-otp');
                          },
                          child: const Text('Skip'),
                        ),
                      ],
                    ),
                  );
                },
                child: const Text(
                  'Skip Photo (Requires Reason)',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.primaryTeal,
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isPhotoUploaded
                      ? () {
                          Navigator.pushNamed(context, '/job-completion-otp', arguments: {
                            'photoPath': _capturedPhoto?.path,
                          });
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFC107),
                    disabledBackgroundColor:
                        const Color(0xFFFFC107).withOpacity(0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Submit Job',
                    style: TextStyle(
                      color: AppColors.darkNavy,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
