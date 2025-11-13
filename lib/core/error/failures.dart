import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;
  
  const Failure(this.message);
  
  @override
  List<Object> get props => [message];
}

class AudioFailure extends Failure {
  const AudioFailure(super.message);
}

class PermissionFailure extends Failure {
  const PermissionFailure(super.message);
}

class StorageFailure extends Failure {
  const StorageFailure(super.message);
}

class HeadphoneFailure extends Failure {
  const HeadphoneFailure(super.message);
}

