import 'package:get_it/get_it.dart';
import '../services/firebase_service.dart';
import '../services/firestore_service.dart';
import '../services/listing_service.dart';
import '../services/nets_qr_service.dart';
import '../services/notification_service.dart';
import '../services/chat_service.dart';

void setupServices() {
  final getIt = GetIt.instance;

  // Register FirestoreService first
  getIt.registerSingleton<FirestoreService>(FirestoreService());

  // Register ListingService
  getIt.registerSingleton<ListingService>(ListingService());

  // Register FirebaseService
  getIt.registerSingleton<FirebaseService>(FirebaseService());

  // Register NETS QR Service
  getIt.registerSingleton<NetsQrService>(NetsQrService());

  // Register Notification Service
  getIt.registerSingleton<NotificationService>(NotificationService());

  // Register Chat Service
  getIt.registerSingleton<ChatService>(ChatService());
}