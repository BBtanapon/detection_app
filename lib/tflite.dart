// import 'dart:io';

// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:tflite/tflite.dart';

// class tflite extends StatefulWidget {
//   @override
//   State<tflite> createState() => _tfliteState();
// }

// class _tfliteState extends State<tflite> {
//   File pickedImage;
//   bool isImageLoad = false;
//   final picker = ImagePicker();

//   List _result;

//   getImageFromGallery() async {
//     final tempStore =
//         await ImagePicker().pickImage(source: ImageSource.gallery);

//     setState(() {
//       pickedImage = File(tempStore.path);
//       isImageLoad = true;
//     });
//     applyModelOnImage(pickedImage);
//   }

//   loadModel() async {
//     String res = await Tflite.loadModel(
//         model: "assets/models/ssd_mobilenet.tflite",
//         labels: "assets/models/labels.txt",
//         numThreads: 1, // defaults to 1
//         isAsset: true,
//         useGpuDelegate: false);
//     // var resultant = await Tflite.loadModel(
//     //     labels: 'assets/label.txt', model: 'assets/converted_model.tflite');
//     // isAsset:
//     // true;
//     // useGpuDelegate:
//     // false;
//     print("Result after loading model: $res");
//   }

//   applyModelOnImage(File file) async {
//     var recognitions = await Tflite.detectObjectOnImage(
//         path: file.path, // required
//         model: "SSDMobileNet",
//         imageMean: 127.5,
//         imageStd: 127.5,
//         threshold: 0.4, // defaults to 0.1
//         numResultsPerClass: 2, // defaults to 5
//         asynch: true // defaults to true
//         );
//   }

//   void initState() {
//     super.initState();
//     loadModel();
//   }

//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('TFLite'),
//       ),
//       body: Container(
//         child: Column(
//           children: [
//             SizedBox(height: 30),
//             isImageLoad
//                 ? Center(
//                     child: Container(
//                       height: 350,
//                       width: 350,
//                       decoration: BoxDecoration(
//                         image: DecorationImage(
//                             image: FileImage(File(pickedImage.path)),
//                             fit: BoxFit.contain),
//                       ),
//                     ),
//                   )
//                 : Container(),
//             SizedBox(height: 30),
//             Text("Level : $_result \nConfidence :")
//           ],
//         ),
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: () {
//           getImageFromGallery();
//         },
//         child: Icon(Icons.photo_album),
//       ),
//     );
//   }
// }

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tflite/tflite.dart';

class StaticImage extends StatefulWidget {
  @override
  _StaticImageState createState() => _StaticImageState();
}

class _StaticImageState extends State<StaticImage> {
  File _image;
  List _recognitions;
  bool _busy;
  double _imageWidth, _imageHeight;

  final picker = ImagePicker();

  // this function loads the model
  loadTfModel() async {
    String res = await Tflite.loadModel(
        model: "assets/models/ssd_mobilenet.tflite",
        labels: "assets/models/labels.txt",
        numThreads: 1, // defaults to 1
        isAsset: true,
        useGpuDelegate: false);
  }

  // this function detects the objects on the image
  detectObject(File image) async {
    var recognitions = await Tflite.detectObjectOnImage(
      path: image.path,
      numResultsPerClass: 1, // defaults to true
    );
    FileImage(image)
        .resolve(ImageConfiguration())
        .addListener((ImageStreamListener((ImageInfo info, bool _) {
          setState(() {
            _imageWidth = info.image.width.toDouble();
            _imageHeight = info.image.height.toDouble();
          });
        })));
    setState(() {
      _recognitions = recognitions;
    });
  }

  @override
  void initState() {
    super.initState();
    _busy = true;
    loadTfModel().then((val) {
      {
        setState(() {
          _busy = false;
        });
      }
    });
  }

  // display the bounding boxes over the detected objects
  List<Widget> renderBoxes(Size screen) {
    if (_recognitions == null) return [];
    if (_imageWidth == null || _imageHeight == null) return [];

    double factorX = screen.width;
    double factorY = _imageHeight / _imageHeight * screen.width;

    Color blue = Colors.blue;

    return _recognitions.map((re) {
      return Container(
        child: Positioned(
            left: re["rect"]["x"] * factorX,
            top: re["rect"]["y"] * factorY,
            width: re["rect"]["w"] * factorX,
            height: re["rect"]["h"] * factorY,
            child: ((re["confidenceInClass"] > 0.50))
                ? Container(
                    decoration: BoxDecoration(
                        border: Border.all(
                      color: blue,
                      width: 3,
                    )),
                    child: Text(
                      "${re["detectedClass"]} ${(re["confidenceInClass"] * 100).toStringAsFixed(0)}%",
                      style: TextStyle(
                        background: Paint()..color = blue,
                        color: Colors.black,
                        fontSize: 15,
                      ),
                    ),
                  )
                : Container()),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;

    List<Widget> stackChildren = [];

    stackChildren.add(Positioned(
      // using ternary operator
      child: _image == null
          ? Container(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text("Please Select an Image"),
                ],
              ),
            )
          : // if not null then
          Container(child: Image.file(_image)),
    ));

    stackChildren.addAll(renderBoxes(size));

    if (_busy) {
      stackChildren.add(Center(
        child: CircularProgressIndicator(),
      ));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Object Detector"),
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          FloatingActionButton(
            heroTag: "Fltbtn2",
            child: Icon(Icons.camera_alt),
            onPressed: getImageFromCamera,
          ),
          SizedBox(
            width: 10,
          ),
          FloatingActionButton(
            heroTag: "Fltbtn1",
            child: Icon(Icons.photo),
            onPressed: getImageFromGallery,
          ),
        ],
      ),
      body: Container(
        alignment: Alignment.center,
        child: Stack(
          children: stackChildren,
        ),
      ),
    );
  }

  // gets image from camera and runs detectObject
  Future getImageFromCamera() async {
    // ignore: deprecated_member_use
    final pickedFile = await picker.getImage(source: ImageSource.camera);

    setState(() {
      if (pickedFile != null) {
        _image = File(pickedFile.path);
      } else {
        print("No image Selected");
      }
    });
    detectObject(_image);
  }

  // gets image from gallery and runs detectObject
  Future getImageFromGallery() async {
    // ignore: deprecated_member_use
    final pickedFile = await picker.getImage(source: ImageSource.gallery);
    setState(() {
      if (pickedFile != null) {
        _image = File(pickedFile.path);
      } else {
        print("No image Selected");
      }
    });
    detectObject(_image);
  }
}
