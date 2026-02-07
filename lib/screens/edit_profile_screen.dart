import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../constants/colors.dart';
import '../constants/text_styles.dart';
import '../models/employee_profile_model.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../utils/responsive_utils.dart';
import '../utils/toast_utils.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen>
    with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;
  EmployeeProfileModel? _profile;
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  // Animation
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _fetchProfile();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _fetchProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final token = _authService.token;
    if (token == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Not authenticated';
      });
      return;
    }

    final result = await _apiService.getProfile(token: token);

    if (!mounted) return;
    if (result['success'] == true) {
      final userData = result['data']['user'] as Map<String, dynamic>;
      setState(() {
        _profile = EmployeeProfileModel.fromJson(userData);
        _nameController.text = _profile?.name ?? '';
        _phoneController.text = _profile?.phone ?? '';
        _isLoading = false;
      });
      // Start entrance animation
      _animationController.forward();
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = result['message'] ?? 'Failed to load profile';
      });
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ToastUtils.showErrorToast(context, 'Failed to pick image');
      }
    }
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ToastUtils.showErrorToast(context, 'Failed to take photo');
      }
    }
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(ResponsiveUtils.r(context, 24)),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(ResponsiveUtils.w(context, 24)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.lightGray,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                SizedBox(height: ResponsiveUtils.h(context, 24)),
                // Title
                Text(
                  'Update Profile Photo',
                  style: AppTextStyles.headline(context).copyWith(
                    fontSize: ResponsiveUtils.sp(context, 20),
                    fontWeight: FontWeight.w700,
                    color: AppColors.darkNavy,
                  ),
                ),
                SizedBox(height: ResponsiveUtils.h(context, 8)),
                Text(
                  'Choose how you\'d like to update your photo',
                  style: AppTextStyles.caption(context).copyWith(
                    color: AppColors.textGray,
                  ),
                ),
                SizedBox(height: ResponsiveUtils.h(context, 24)),
                // Options
                _buildPickerOption(
                  icon: Icons.photo_library_rounded,
                  title: 'Choose from Gallery',
                  subtitle: 'Select an existing photo',
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage();
                  },
                ),
                SizedBox(height: ResponsiveUtils.h(context, 12)),
                _buildPickerOption(
                  icon: Icons.camera_alt_rounded,
                  title: 'Take a Photo',
                  subtitle: 'Use your camera',
                  onTap: () {
                    Navigator.pop(context);
                    _takePhoto();
                  },
                ),
                SizedBox(height: ResponsiveUtils.h(context, 16)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPickerOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(ResponsiveUtils.r(context, 16)),
        child: Container(
          padding: EdgeInsets.all(ResponsiveUtils.w(context, 16)),
          decoration: BoxDecoration(
            color: AppColors.veryLightGray,
            borderRadius: BorderRadius.circular(ResponsiveUtils.r(context, 16)),
            border: Border.all(
              color: AppColors.lightGray.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: ResponsiveUtils.r(context, 52),
                height: ResponsiveUtils.r(context, 52),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primaryTeal,
                      AppColors.primaryTeal.withValues(alpha: 0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(ResponsiveUtils.r(context, 14)),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryTeal.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: ResponsiveUtils.r(context, 24),
                ),
              ),
              SizedBox(width: ResponsiveUtils.w(context, 16)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.body(context).copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.darkNavy,
                      ),
                    ),
                    SizedBox(height: ResponsiveUtils.h(context, 2)),
                    Text(
                      subtitle,
                      style: AppTextStyles.caption(context).copyWith(
                        color: AppColors.textGray,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textGray,
                size: ResponsiveUtils.r(context, 24),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final token = _authService.token;
    if (token == null) {
      ToastUtils.showErrorToast(context, 'Not authenticated');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final result = await _apiService.updateProfile(
      token: token,
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      email: _profile?.email,
      profilePhotoPath: _selectedImage?.path,
    );

    if (!mounted) return;

    setState(() {
      _isSaving = false;
    });

    if (result['success'] == true) {
      // Update the profile data from response
      if (result['data']?['user'] != null) {
        final userData = result['data']['user'] as Map<String, dynamic>;
        setState(() {
          _profile = EmployeeProfileModel.fromJson(userData);
          _selectedImage = null; // Clear selected image after successful upload
        });
      }
      ToastUtils.showSuccessToast(context, 'Profile updated successfully');
      Navigator.pop(context, true); // Return true to indicate profile was updated
    } else {
      ToastUtils.showErrorToast(
        context,
        result['message'] ?? 'Failed to update profile',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.veryLightGray,
      body: CustomScrollView(
        slivers: [
          // Premium gradient app bar
          SliverAppBar(
            expandedHeight: ResponsiveUtils.h(context, 120),
            pinned: true,
            backgroundColor: AppColors.primaryTeal,
            elevation: 0,
            leading: IconButton(
              icon: Container(
                padding: EdgeInsets.all(ResponsiveUtils.w(context, 8)),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white,
                  size: ResponsiveUtils.r(context, 18),
                ),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              title: Text(
                'Edit Profile',
                style: AppTextStyles.headline(context).copyWith(
                  fontSize: ResponsiveUtils.sp(context, 18),
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primaryTeal,
                      AppColors.primaryTeal.withValues(alpha: 0.85),
                      const Color(0xFF00897B),
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    // Decorative circles
                    Positioned(
                      top: -20,
                      right: -30,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -40,
                      left: -20,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.05),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Content
          SliverToBoxAdapter(
            child: _buildBody(),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return SizedBox(
        height: MediaQuery.of(context).size.height * 0.6,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 48,
                height: 48,
                child: CircularProgressIndicator(
                  color: AppColors.primaryTeal,
                  strokeWidth: 3,
                ),
              ),
              SizedBox(height: ResponsiveUtils.h(context, 16)),
              Text(
                'Loading profile...',
                style: AppTextStyles.caption(context).copyWith(
                  color: AppColors.textGray,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return SizedBox(
        height: MediaQuery.of(context).size.height * 0.6,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(ResponsiveUtils.w(context, 20)),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.error_outline_rounded,
                  size: ResponsiveUtils.r(context, 48),
                  color: Colors.red.shade400,
                ),
              ),
              SizedBox(height: ResponsiveUtils.h(context, 20)),
              Text(
                _errorMessage!,
                style: AppTextStyles.body(context).copyWith(
                  color: AppColors.textGray,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: ResponsiveUtils.h(context, 24)),
              ElevatedButton.icon(
                onPressed: _fetchProfile,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryTeal,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    horizontal: ResponsiveUtils.w(context, 24),
                    vertical: ResponsiveUtils.h(context, 12),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Padding(
          padding: EdgeInsets.all(ResponsiveUtils.w(context, 20)),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // Profile Photo Section
                _buildProfilePhotoSection(),
                SizedBox(height: ResponsiveUtils.h(context, 28)),

                // Form Fields Card
                _buildFormCard(),
                SizedBox(height: ResponsiveUtils.h(context, 24)),

                // Save Button
                _buildSaveButton(),
                SizedBox(height: ResponsiveUtils.h(context, 32)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfilePhotoSection() {
    return Center(
      child: Column(
        children: [
          // Profile image with premium styling
          GestureDetector(
            onTap: _showImagePickerOptions,
            child: Stack(
              children: [
                // Outer glow ring
                Container(
                  width: ResponsiveUtils.r(context, 148),
                  height: ResponsiveUtils.r(context, 148),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.primaryTeal.withValues(alpha: 0.3),
                        AppColors.primaryTeal.withValues(alpha: 0.1),
                      ],
                    ),
                  ),
                  child: Center(
                    child: Container(
                      width: ResponsiveUtils.r(context, 136),
                      height: ResponsiveUtils.r(context, 136),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.white,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryTeal.withValues(alpha: 0.2),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(4),
                      child: ClipOval(
                        child: _selectedImage != null
                            ? Image.file(
                                _selectedImage!,
                                fit: BoxFit.cover,
                                width: ResponsiveUtils.r(context, 128),
                                height: ResponsiveUtils.r(context, 128),
                              )
                            : _profile?.profilePhotoUrl != null
                                ? Image.network(
                                    _profile!.profilePhotoUrl!,
                                    fit: BoxFit.cover,
                                    width: ResponsiveUtils.r(context, 128),
                                    height: ResponsiveUtils.r(context, 128),
                                    errorBuilder: (context, error, stackTrace) =>
                                        _buildDefaultAvatar(),
                                    loadingBuilder: (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return Container(
                                        color: AppColors.veryLightGray,
                                        child: Center(
                                          child: CircularProgressIndicator(
                                            color: AppColors.primaryTeal,
                                            strokeWidth: 2,
                                          ),
                                        ),
                                      );
                                    },
                                  )
                                : _buildDefaultAvatar(),
                      ),
                    ),
                  ),
                ),
                // Camera button
                Positioned(
                  bottom: 4,
                  right: 4,
                  child: Container(
                    padding: EdgeInsets.all(ResponsiveUtils.w(context, 12)),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.primaryTeal,
                          const Color(0xFF00897B),
                        ],
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryTeal.withValues(alpha: 0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.camera_alt_rounded,
                      color: Colors.white,
                      size: ResponsiveUtils.r(context, 20),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: ResponsiveUtils.h(context, 16)),
          // Name display
          if (_profile?.name case final name?) ...[
            Text(
              name,
              style: AppTextStyles.headline(context).copyWith(
                fontSize: ResponsiveUtils.sp(context, 22),
                fontWeight: FontWeight.w700,
                color: AppColors.darkNavy,
              ),
            ),
            SizedBox(height: ResponsiveUtils.h(context, 4)),
          ],
          Text(
            'Tap photo to change',
            style: AppTextStyles.caption(context).copyWith(
              color: AppColors.textGray,
              fontSize: ResponsiveUtils.sp(context, 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.veryLightGray,
            AppColors.lightGray.withValues(alpha: 0.5),
          ],
        ),
      ),
      child: Icon(
        Icons.person_rounded,
        size: ResponsiveUtils.r(context, 64),
        color: AppColors.primaryTeal.withValues(alpha: 0.4),
      ),
    );
  }

  Widget _buildFormCard() {
    return Container(
      padding: EdgeInsets.all(ResponsiveUtils.w(context, 24)),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(ResponsiveUtils.r(context, 20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: AppColors.primaryTeal.withValues(alpha: 0.04),
            blurRadius: 40,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(ResponsiveUtils.w(context, 10)),
                decoration: BoxDecoration(
                  color: AppColors.primaryTeal.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.person_outline_rounded,
                  color: AppColors.primaryTeal,
                  size: ResponsiveUtils.r(context, 20),
                ),
              ),
              SizedBox(width: ResponsiveUtils.w(context, 12)),
              Text(
                'Personal Information',
                style: AppTextStyles.subtitle(context).copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.darkNavy,
                  fontSize: ResponsiveUtils.sp(context, 16),
                ),
              ),
            ],
          ),
          SizedBox(height: ResponsiveUtils.h(context, 24)),

          // Name Field
          _buildTextField(
            label: 'Full Name',
            controller: _nameController,
            icon: Icons.badge_outlined,
            enabled: true,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your name';
              }
              return null;
            },
          ),
          SizedBox(height: ResponsiveUtils.h(context, 20)),

          // Phone Field (Read-only)
          _buildTextField(
            label: 'Phone Number',
            controller: _phoneController,
            icon: Icons.phone_outlined,
            enabled: false,
            helperText: 'Phone number cannot be changed',
          ),

          // Vendor Info (if available)
          if (_profile?.vendor != null) ...[
            SizedBox(height: ResponsiveUtils.h(context, 24)),
            Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    AppColors.lightGray.withValues(alpha: 0.5),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            SizedBox(height: ResponsiveUtils.h(context, 24)),
            _buildVendorInfo(),
          ],
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    bool enabled = true,
    String? helperText,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.caption(context).copyWith(
            color: AppColors.textGray,
            fontWeight: FontWeight.w600,
            fontSize: ResponsiveUtils.sp(context, 13),
            letterSpacing: 0.3,
          ),
        ),
        SizedBox(height: ResponsiveUtils.h(context, 10)),
        TextFormField(
          controller: controller,
          enabled: enabled,
          validator: validator,
          style: AppTextStyles.body(context).copyWith(
            color: enabled ? AppColors.darkNavy : AppColors.textGray,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            prefixIcon: Padding(
              padding: EdgeInsets.only(left: ResponsiveUtils.w(context, 16), right: ResponsiveUtils.w(context, 12)),
              child: Icon(
                icon,
                color: enabled ? AppColors.primaryTeal : AppColors.lightGray,
                size: ResponsiveUtils.r(context, 22),
              ),
            ),
            prefixIconConstraints: BoxConstraints(
              minWidth: ResponsiveUtils.r(context, 50),
            ),
            filled: true,
            fillColor: enabled
                ? AppColors.veryLightGray
                : AppColors.lightGray.withValues(alpha: 0.15),
            contentPadding: EdgeInsets.symmetric(
              horizontal: ResponsiveUtils.w(context, 16),
              vertical: ResponsiveUtils.h(context, 16),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(ResponsiveUtils.r(context, 14)),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(ResponsiveUtils.r(context, 14)),
              borderSide: BorderSide(
                color: AppColors.lightGray.withValues(alpha: 0.3),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(ResponsiveUtils.r(context, 14)),
              borderSide: BorderSide(
                color: AppColors.primaryTeal,
                width: 2,
              ),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(ResponsiveUtils.r(context, 14)),
              borderSide: BorderSide(
                color: AppColors.lightGray.withValues(alpha: 0.2),
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(ResponsiveUtils.r(context, 14)),
              borderSide: BorderSide(color: Colors.red.shade300),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(ResponsiveUtils.r(context, 14)),
              borderSide: BorderSide(color: Colors.red.shade400, width: 2),
            ),
          ),
        ),
        if (helperText != null) ...[
          SizedBox(height: ResponsiveUtils.h(context, 8)),
          Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: ResponsiveUtils.r(context, 14),
                color: AppColors.textGray.withValues(alpha: 0.7),
              ),
              SizedBox(width: ResponsiveUtils.w(context, 6)),
              Text(
                helperText,
                style: AppTextStyles.caption(context).copyWith(
                  color: AppColors.textGray.withValues(alpha: 0.8),
                  fontSize: ResponsiveUtils.sp(context, 12),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildVendorInfo() {
    final vendor = _profile!.vendor!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(ResponsiveUtils.w(context, 10)),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.business_rounded,
                color: Colors.amber.shade700,
                size: ResponsiveUtils.r(context, 20),
              ),
            ),
            SizedBox(width: ResponsiveUtils.w(context, 12)),
            Text(
              'Vendor Information',
              style: AppTextStyles.subtitle(context).copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.darkNavy,
                fontSize: ResponsiveUtils.sp(context, 16),
              ),
            ),
          ],
        ),
        SizedBox(height: ResponsiveUtils.h(context, 16)),
        Container(
          padding: EdgeInsets.all(ResponsiveUtils.w(context, 16)),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.amber.withValues(alpha: 0.08),
                Colors.amber.withValues(alpha: 0.03),
              ],
            ),
            borderRadius: BorderRadius.circular(ResponsiveUtils.r(context, 16)),
            border: Border.all(
              color: Colors.amber.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              if (vendor.logoUrl != null)
                Container(
                  width: ResponsiveUtils.r(context, 52),
                  height: ResponsiveUtils.r(context, 52),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(ResponsiveUtils.r(context, 14)),
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(ResponsiveUtils.r(context, 14)),
                    child: Image.network(
                      vendor.logoUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Icon(
                        Icons.business_rounded,
                        color: Colors.amber.shade700,
                        size: ResponsiveUtils.r(context, 24),
                      ),
                    ),
                  ),
                )
              else
                Container(
                  width: ResponsiveUtils.r(context, 52),
                  height: ResponsiveUtils.r(context, 52),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(ResponsiveUtils.r(context, 14)),
                    color: Colors.amber.withValues(alpha: 0.15),
                  ),
                  child: Icon(
                    Icons.business_rounded,
                    color: Colors.amber.shade700,
                    size: ResponsiveUtils.r(context, 24),
                  ),
                ),
              SizedBox(width: ResponsiveUtils.w(context, 16)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vendor.name,
                      style: AppTextStyles.body(context).copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.darkNavy,
                      ),
                    ),
                    if (vendor.phone != null && vendor.phone!.isNotEmpty) ...[
                      SizedBox(height: ResponsiveUtils.h(context, 4)),
                      Row(
                        children: [
                          Icon(
                            Icons.phone_outlined,
                            size: ResponsiveUtils.r(context, 14),
                            color: AppColors.textGray,
                          ),
                          SizedBox(width: ResponsiveUtils.w(context, 4)),
                          Text(
                            vendor.phone!,
                            style: AppTextStyles.caption(context).copyWith(
                              color: AppColors.textGray,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return Container(
      width: double.infinity,
      height: ResponsiveUtils.h(context, 56),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(ResponsiveUtils.r(context, 16)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _isSaving
              ? [
                  AppColors.lightGray,
                  AppColors.lightGray,
                ]
              : [
                  AppColors.primaryTeal,
                  const Color(0xFF00897B),
                ],
        ),
        boxShadow: _isSaving
            ? []
            : [
                BoxShadow(
                  color: AppColors.primaryTeal.withValues(alpha: 0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isSaving ? null : _saveProfile,
          borderRadius: BorderRadius.circular(ResponsiveUtils.r(context, 16)),
          child: Center(
            child: _isSaving
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: AppColors.textGray,
                          strokeWidth: 2.5,
                        ),
                      ),
                      SizedBox(width: ResponsiveUtils.w(context, 12)),
                      Text(
                        'Saving...',
                        style: AppTextStyles.button(context).copyWith(
                          fontSize: ResponsiveUtils.sp(context, 16),
                          color: AppColors.textGray,
                        ),
                      ),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check_circle_outline_rounded,
                        color: Colors.white,
                        size: ResponsiveUtils.r(context, 22),
                      ),
                      SizedBox(width: ResponsiveUtils.w(context, 10)),
                      Text(
                        'Save Changes',
                        style: AppTextStyles.button(context).copyWith(
                          fontSize: ResponsiveUtils.sp(context, 16),
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
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
