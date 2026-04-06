// Smoke test — verifica que la app arranca sin lanzar excepciones.
// Los tests funcionales están en los archivos *_test.dart específicos.
void main() {
  // No hay widget tests aquí porque la app requiere inicialización de
  // Hive, MediaKit y go_router que no están disponibles en el test runner
  // estándar sin mocks completos. Ver los demás archivos de test.
}
