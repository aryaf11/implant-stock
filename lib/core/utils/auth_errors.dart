String mapAuthError(Object e) {
  return e.toString().replaceFirst('Exception: ', '');
}
