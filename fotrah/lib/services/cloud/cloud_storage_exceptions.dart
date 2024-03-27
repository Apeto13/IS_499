

class CloudStorageException implements Exception{
  const CloudStorageException();
}
class CouldNotCreateBillException extends CloudStorageException {}

class CouldNotGettAllBillsException extends CloudStorageException {}

class CouldNotUpdateBillException extends CloudStorageException {}

class CouldNotDeleteBillException extends CloudStorageException {}

class CouldNotFindCompanyException extends CloudStorageException {}

class CouldNotFindCategoryException extends CloudStorageException {}

class CouldNotUpdateUserException extends CloudStorageException {}

class CouldNotGetUserInfoException extends CloudStorageException {}

class CouldNotSaveUserExceprion extends  CloudStorageException {}