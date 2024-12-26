const errorTypeNetwork = "NETWORK_ERROR";
const errorTypePermission = "PERMISSION_ERROR";
const errorTypeTime = "TIME_ERROR";

// 错误的类型, 方便照展示和谐的提示
String errorType(String error) {
  // EXCEPTION
  if (error.contains("timeout") ||
      error.contains("tcp connect") ||
      error.contains("connection refused") ||
      error.contains("deadline") ||
      error.contains("connection abort") ||
      error.contains("certificate") ||
      error.contains("x509") ||
      error.contains("ssl")) {
    return errorTypeNetwork;
  }
  if (error.contains("permission denied")) {
    return errorTypePermission;
  }
  if (error.contains("time is not synchronize")) {
    return errorTypeTime;
  }
  return "";
}
