import 'package:comfyui_dart_sdk/comfyui_dart_sdk.dart';

void main() async {
  final api = ComfyApi('http://localhost:5000');
  final socket = await ComfySocket.connect('http://localhost:5000', '');

  // Fetching data from API
  final response = await api.getPrompt();
  print(response);

  // Fetching images over WebSocket
  final promptId = 'examplePromptId';
  await for (final image in socket.getImages(promptId)) {
    print('Received image with size: ${image.length}');
  }

  await socket.close();
}
