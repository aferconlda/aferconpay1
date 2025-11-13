
import 'dart:io';
import 'package:afercon_pay/models/user_model.dart';
import 'package:afercon_pay/services/auth_service.dart';
import 'package:afercon_pay/services/firestore_service.dart';
import 'package:afercon_pay/services/verification_service.dart';
import 'package:afercon_pay/widgets/custom_app_bar.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

class KycVerificationScreen extends StatefulWidget {
  const KycVerificationScreen({super.key});

  @override
  State<KycVerificationScreen> createState() => _KycVerificationScreenState();
}

class _KycVerificationScreenState extends State<KycVerificationScreen> {
  final AuthService _authService = AuthService();
  final VerificationService _verificationService = VerificationService();
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  UserModel? _currentUser;
  XFile? _frontImageFile;
  XFile? _backImageFile;
  XFile? _selfieImageFile;
  bool _isSubmitting = false;
  bool _isPageLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final authUser = _authService.getCurrentUser();
    if (mounted) {
      if (authUser != null) {
        // CORREÇÃO: Usar o nome de método correto 'getUserStream'.
        _firestoreService.getUserStream(authUser.uid).listen((userModel) {
          if (mounted) {
            setState(() {
              _currentUser = userModel;
              _isPageLoading = false;
            });
          }
        });
      } else {
        setState(() {
          _isPageLoading = false;
        });
      }
    }
  }

  Future<ImageSource?> _showImageSourceDialog() async {
    return await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Câmara'),
              onTap: () => Navigator.of(context).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galeria'),
              onTap: () => Navigator.of(context).pop(ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleImageSelection(void Function(XFile?) onImageSelected) async {
    try {
      final source = await _showImageSourceDialog();
      if (source == null) return;

      final XFile? image = await _picker.pickImage(source: source);
      if (image != null) {
        onImageSelected(image);
      }
    } on PlatformException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Falha ao aceder à imagem. Verifique as permissões da aplicação. Erro: ${e.code}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ocorreu um erro ao selecionar a imagem: $e')),
      );
    }
  }

  Future<String> _uploadFile(XFile file, String path) async {
    final ref = _storage.ref(path);
    final uploadTask = await ref.putData(await file.readAsBytes());
    return await uploadTask.ref.getDownloadURL();
  }

  Future<void> _submitKyc() async {
    FirebaseAnalytics.instance.logEvent(name: 'begin_kyc');

    if (_frontImageFile == null || _backImageFile == null || _selfieImageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, anexe todas as três imagens.')),
      );
      return;
    }

    if (_currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Utilizador não autenticado. Impossível submeter.')),
      );
      return;
    }
    final userId = _currentUser!.uid;

    setState(() => _isSubmitting = true);

    try {
      final frontImageUrlFuture = _uploadFile(_frontImageFile!, 'kyc_documents/$userId/front.jpg');
      final backImageUrlFuture = _uploadFile(_backImageFile!, 'kyc_documents/$userId/back.jpg');
      final selfieImageUrlFuture = _uploadFile(_selfieImageFile!, 'kyc_documents/$userId/selfie.jpg');

      final urls = await Future.wait([frontImageUrlFuture, backImageUrlFuture, selfieImageUrlFuture]);

      await _verificationService.submitRequest(
        userId: userId,
        frontImageUrl: urls[0],
        backImageUrl: urls[1],
        selfieImageUrl: urls[2],
      );

      if (mounted) {
        FirebaseAnalytics.instance.logEvent(name: 'submit_kyc_application');

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Submissão Recebida'),
            content: const Text('Os seus documentos foram enviados com sucesso e estão em análise.'),
            actions: [
              TextButton(
                child: const Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ocorreu um erro: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: Text('Verificação de Identidade')),
      body: _isPageLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    final status = _currentUser?.kycStatus;

    if (status == KycStatus.pending || status == KycStatus.approved) {
      return _buildStatusIndicator(status!);
    } else {
      return _buildSubmissionForm();
    }
  }

  Widget _buildStatusIndicator(KycStatus status) {
    String title;
    String message;
    IconData icon;
    Color iconColor;

    switch (status) {
      case KycStatus.pending:
        title = 'Documentos em Análise';
        message = 'Recebemos os seus documentos e a nossa equipa está a analisá-los. Será notificado assim que o processo terminar.';
        icon = Icons.hourglass_top_rounded;
        iconColor = Colors.orange;
        break;
      case KycStatus.approved:
        title = 'Conta Verificada';
        message = 'Parabéns! A sua identidade foi verificada com sucesso. Já pode aceder a todas as funcionalidades.';
        icon = Icons.check_circle_rounded;
        iconColor = Colors.green;
        break;
      default:
        return const SizedBox.shrink();
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, size: 80, color: iconColor),
            SizedBox(height: 24.h),
            Text(title, style: Theme.of(context).textTheme.headlineSmall, textAlign: TextAlign.center),
            SizedBox(height: 16.h),
            Text(message, style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmissionForm() {
    return Stack(
      children: [
        SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 24.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_currentUser?.kycStatus == KycStatus.rejected)
                Padding(
                  padding: EdgeInsets.only(bottom: 24.h),
                  child: Text(
                    'O seu pedido anterior foi rejeitado. Por favor, submeta novamente os seus documentos com mais atenção.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.error),
                    textAlign: TextAlign.center,
                  ),
                ),
              Text(
                'Para garantir a segurança da sua conta, anexe fotos nítidas do seu documento e uma selfie.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24.h),
              _buildImagePickerBox(
                title: 'Frente do Documento',
                file: _frontImageFile,
                onTap: () => _handleImageSelection((image) => setState(() => _frontImageFile = image)),
              ),
              SizedBox(height: 16.h),
              _buildImagePickerBox(
                title: 'Verso do Documento',
                file: _backImageFile,
                onTap: () => _handleImageSelection((image) => setState(() => _backImageFile = image)),
              ),
              SizedBox(height: 16.h),
              _buildImagePickerBox(
                title: 'Selfie com o Documento',
                file: _selfieImageFile,
                onTap: () => _handleImageSelection((image) => setState(() => _selfieImageFile = image)),
              ),
              SizedBox(height: 32.h),
              ElevatedButton(
                style: ElevatedButton.styleFrom(minimumSize: Size.fromHeight(50.h)),
                onPressed: _isSubmitting ? null : _submitKyc,
                child: const Text('Submeter para Verificação'),
              ),
            ],
          ),
        ),
        if (_isSubmitting)
          Container(
            color: Colors.black.withAlpha(128),
            child: const Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }

  Widget _buildImagePickerBox({
    required String title,
    required XFile? file,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: _isSubmitting ? null : onTap,
      child: Container(
        height: 150.h,
        width: double.infinity,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(12),
          color: Colors.grey.shade50,
        ),
        child: file != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: kIsWeb
                    ? Image.network(file.path, fit: BoxFit.cover, width: double.infinity, height: double.infinity)
                    : Image.file(File(file.path), fit: BoxFit.cover),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_a_photo_outlined, size: 40.r, color: Colors.grey.shade600),
                  SizedBox(height: 8.h),
                  Text(title, style: TextStyle(color: Colors.grey.shade700)),
                ],
              ),
      ),
    );
  }
}
