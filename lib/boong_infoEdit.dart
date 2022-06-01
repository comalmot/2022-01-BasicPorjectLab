import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:our_town_boongsaegwon/boong_info.dart';
import 'boong_menuEdit.dart';
import 'dart:io';
import 'boong_timeEdit.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io' as IO;
import 'package:get/get.dart';
import 'token_controller.dart';
import 'main.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '내 가게 정보',
      home: infoEdit("", "", "", "", "", "", null),
    );
  }
}

// 기존 데이터를 불러온 뒤 저장하기 위한 전역변수.
GetStoreInfo? initStoreInfo;

class SetStoreInfo {
  String? error;
  bool? ok;

  SetStoreInfo({this.error, this.ok});

  SetStoreInfo.fromJson(Map<String, dynamic> json) {
    this.error = json['error'];
    this.ok = json['ok'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['error'] = this.error;
    data['ok'] = this.ok;
    return data;
  }
}

class GetStoreInfo {
  String category = "";
  String? error;
  List<Map<String, dynamic>>? menu_info;
  String name = "";
  bool ok = false;
  String? store_description;
  String store_name = "";
  List<String>? store_open_info;
  List<String>? store_photo;

  GetStoreInfo(
      this.category,
      this.error,
      this.menu_info,
      this.name,
      this.ok,
      this.store_description,
      this.store_name,
      this.store_open_info,
      this.store_photo);

  GetStoreInfo.fromJson(Map<String, dynamic> json)
      : category = json['category'],
        error = json['error'],
        menu_info = json['menu_info']['menu'],
        name = json['name'],
        ok = json['ok'],
        store_description = json['store_description'],
        store_name = json['store_name'],
        store_open_info = json['store_open_info']['information'],
        store_photo = json['store_photo']['photo_urls'];

  Map<String, dynamic> toJson() => {
        'category': category,
        'error': error,
        'menu_info': menu_info,
        'name': name,
        'ok': ok,
        'store_description': store_description,
        'store_name': store_name,
        'store_open_info': store_open_info,
        'store_photo': store_photo,
      };
}

class infoEdit extends StatefulWidget {
  final String token;
  final String id;
  // 2022.06.01 진건승.
  // 가게 이름, 가게 설명, 사진을 GetX로 하려다가, 이미 Routes가 GetX 기반으로 되어있지 않아 개발이 꼬일 것 같아서 GetX 사용 안함.
  final String saveState_storeName; // 가게 이름
  final String saveState_storeDesc; // 가게 설명
  final String saveState_storeTime; // 운영 시간
  final String saveState_storeCate; // 가게 카테고리
  final List<File>? saveState_storeImages; // 가게 이미지

  //final List<File> saveState_menuImages;

  const infoEdit(
      this.token,
      this.id,
      this.saveState_storeName,
      this.saveState_storeDesc,
      this.saveState_storeTime,
      this.saveState_storeCate,
      this.saveState_storeImages);
  @override
  infoEditState createState() => infoEditState();
}

class infoEditState extends State<infoEdit> {
  String name = "";
  static List<String> entries = <String>[];
  static List<Map<String, dynamic>> menus = [];
  List<File> images = <File>[];
  List<String> enc_images = <String>[];
  int a = 0;

  // 가게 이름, 가게 설명, 영업 시간, 메뉴명 및 가격에 접근하기 위한 컨트롤러 선언
  TextEditingController _Store_Name_Controller = TextEditingController();
  TextEditingController _Store_Desc_Controller = TextEditingController();
  TextEditingController _Store_Time_Controller = TextEditingController();
  TextEditingController _Store_Menu_Controller = TextEditingController();
  TextEditingController _Store_Cate_Controller = TextEditingController();

  void _setImage() async {
    var picker = ImagePicker();
    var image = await picker.pickImage(source: ImageSource.gallery);
    var userImage;
    if (image != null) {
      setState(() {
        userImage = File(image.path);
        images.add(userImage);

        // 이미지 base64 인코딩
        final bytes = userImage.readAsBytesSync();
        enc_images.add(base64Encode(bytes));

        a++;
      });
    }
  }

  Future<GetStoreInfo> fetchGetStoreInfo(String id) async {
    final msg = jsonEncode({"id": id});
    final response =
        await http.post(Uri.parse('http://boongsaegwon.kro.kr/get_store_info'),
            headers: {
              'Content-Type': 'application/json; charset=UTF-8',
              HttpHeaders.authorizationHeader: 'Bearer ${widget.token}',
            },
            body: msg);

    if (response.statusCode == 200) {
      // If the server did return a 200 OK response,
      // then parse the JSON.

      if (GetStoreInfo.fromJson(json.decode(response.body)).ok == true) {
        final _logoutSnackBar = SnackBar(
          content: Text("로그아웃 성공."),
        );

        ScaffoldMessenger.of(context).showSnackBar(_logoutSnackBar);

        initStoreInfo = GetStoreInfo.fromJson(json.decode(response.body));
        Navigator.pop(context);
      }
      return GetStoreInfo.fromJson(json.decode(response.body));
    } else {
      final _logoutSnackBar = SnackBar(
        content: Text("로그아웃 실패."),
      );

      ScaffoldMessenger.of(context).showSnackBar(_logoutSnackBar);
      throw Exception('Error : Failed to logout');
    }
  }

  Future<SetStoreInfo> fetchSetStoreInfo(
      String id,
      String name, // 변경될 가게 이름..?
      String store_name,
      String category,
      String store_description,
      List<String> store_open_info,
      List<String> store_photo,
      List<Map<String, dynamic>> menu) async {
    Map<String, dynamic> requestBody = {
      'id': id,
      'name': name,
      'store_name': store_name,
      'category': category,
      'store_description': store_description,
      'store_open_info': {
        'information': store_open_info,
      },
      'store_photo': {
        'photo_urls': store_photo,
      },
      'menu_info': {
        'menu': menu,
      },
    };
    final msg = jsonEncode(requestBody);
    final response =
        await http.post(Uri.parse('http://boongsaegwon.kro.kr/set_store_info'),
            headers: {
              'Content-Type': 'application/json; charset=UTF-8',
              HttpHeaders.authorizationHeader: 'Bearer ${widget.token}',
            },
            body: msg);

    print(requestBody); // for Debug

    if (response.statusCode == 200) {
      // If the server did return a 200 OK response,
      // then parse the JSON.

      if (SetStoreInfo.fromJson(json.decode(response.body)).ok == true) {
        final _loginSnackBar = SnackBar(
          content: Text("가게 정보 입력 완료."),
        );

        ScaffoldMessenger.of(context).showSnackBar(_loginSnackBar);
      }
      return SetStoreInfo.fromJson(json.decode(response.body));
    } else {
      final _loginSnackBar = SnackBar(
        content: Text("가게 정보 입력 실패."),
      );

      ScaffoldMessenger.of(context).showSnackBar(_loginSnackBar);
      throw Exception('Error : Failed to login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text("가게 정보 수정"),
        backgroundColor: Colors.black26,
      ),
      body: Container(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                "내 가게 정보",
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
              ),
              Container(
                width: 100,
                child: Divider(color: Colors.black, thickness: 2.0),
              ),
              Text(
                "점포명",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Container(
                margin: EdgeInsets.all(10.0),
                child: TextField(
                  onSubmitted: ((value) {
                    //widget.saveState_storeName = _Store_Name_Controller.text;
                  }),
                  controller: _Store_Name_Controller,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(6.0)),
                    ),
                  ),
                ),
              ),
              Text(
                "카테고리",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Container(
                margin: EdgeInsets.all(10.0),
                child: TextField(
                  controller: _Store_Cate_Controller,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(6.0)),
                    ),
                  ),
                ),
              ),
              Text(
                "가게 사진 (" + '$a' + "/99)",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Container(
                padding: EdgeInsets.fromLTRB(100, 0, 100, 0),
                child: Row(
                  children: [
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: images.length,
                        itemBuilder: (BuildContext context, int index) {
                          return Container(
                            color: Colors.grey,
                            child: Center(
                              child: Image(
                                image: FileImage(images[index]),
                              ), // 사진 업로드 체크용. 이후 갤러리 열어서 사진 넘기는 쪽으로 수정 예정
                            ),
                          );
                        },
                      ),
                    )
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  if (this.mounted) {
                    setState(() {
                      _setImage();
                      //widget.token,
                      //widget.id,
                      _Store_Name_Controller.text = widget.saveState_storeName;
                      _Store_Desc_Controller.text = widget.saveState_storeDesc;
                      _Store_Cate_Controller.text = widget.saveState_storeCate;
                    });
                  }
                },
                style: ButtonStyle(
                    textStyle: MaterialStateProperty.all(
                        TextStyle(fontSize: 20, color: Colors.white)),
                    backgroundColor: MaterialStateProperty.all(Colors.grey)),
                child: Text("+"),
              ),
              Container(
                  child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(
                    "가게 설명",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Container(
                    width: 100,
                    child: Divider(color: Colors.black, thickness: 1.0),
                  ),
                  TextField(
                    controller: _Store_Desc_Controller,
                    keyboardType: TextInputType.multiline,
                    maxLines: 5,
                    minLines: 1,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(6.0)),
                      ),
                    ),
                  ),
                  Container(
                    margin: EdgeInsets.all(8.0),
                  ),
                  Text(
                    "영업시간",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  ListView.separated(
                    shrinkWrap: true,
                    itemCount: entries.length,
                    itemBuilder: (BuildContext context, int index) {
                      return Container(
                          height: 50,
                          color: Colors.black26,
                          child: Center(
                            child: Text(entries[index]),
                          ));
                    },
                    separatorBuilder: (BuildContext context, int index) =>
                        const Divider(),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      final returnData = await Navigator.push(context,
                          MaterialPageRoute(builder: (context) => timeEdit()));
                      if (returnData != null) {
                        int i = timeEditState.returnData.length;
                        entries.add(timeEditState.returnData[i - 1]);

                        print("modified: $returnData");
                        //print("modified: $entries");
                        // 화면 새로고침
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                              builder: (context) => infoEdit(
                                  widget.token,
                                  widget.id,
                                  widget.saveState_storeName,
                                  widget.saveState_storeDesc,
                                  widget.saveState_storeTime,
                                  widget.saveState_storeCate,
                                  widget.saveState_storeImages)),
                          (Route<dynamic> route) => false,
                        );
                      }
                    },
                    style: ButtonStyle(
                        textStyle: MaterialStateProperty.all(
                            TextStyle(fontSize: 20, color: Colors.white)),
                        backgroundColor:
                            MaterialStateProperty.all(Colors.grey)),
                    child: Text("+"),
                  ),
                  Container(
                    margin: EdgeInsets.all(8.0),
                  ),
                  const Text(
                    "메뉴명/가격",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  ListView.separated(
                    shrinkWrap: true,
                    itemCount: menus.length,
                    itemBuilder: (BuildContext context, int index) {
                      return Container(
                          height: 50,
                          color: Colors.black26,
                          child: Center(
                            child: Text(menus[index]['name'] +
                                '     ' +
                                menus[index]['price']),
                          ));
                    },
                    separatorBuilder: (BuildContext context, int index) =>
                        const Divider(),
                  ),
                  ElevatedButton(
                    // 이후 화면 구성 후 처리 예정
                    onPressed: () async {
                      final returnData = await Navigator.push(context,
                          MaterialPageRoute(builder: (context) => menuEdit()));
                      if (returnData != null) {
                        int i = menuEditState.returnData.length;
                        print(returnData);

                        String MainMapKeyTemp = i.toString();
                        menus.add(returnData);

                        print("modified: $returnData");
                        // 화면 새로고침
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                              builder: (context) => infoEdit(
                                  widget.token,
                                  widget.id,
                                  widget.saveState_storeName,
                                  widget.saveState_storeDesc,
                                  widget.saveState_storeTime,
                                  widget.saveState_storeCate,
                                  widget.saveState_storeImages)),
                          (Route<dynamic> route) => false,
                        );
                      }
                    },
                    style: ButtonStyle(
                        textStyle: MaterialStateProperty.all(
                            TextStyle(fontSize: 20, color: Colors.white)),
                        backgroundColor:
                            MaterialStateProperty.all(Colors.grey)),
                    child: Text("+"),
                  ),
                ],
              )),
              Container(
                margin: EdgeInsets.all(10.0),
              ),
              Container(
                margin: EdgeInsets.fromLTRB(0, 70, 0, 0),
                padding: EdgeInsets.fromLTRB(0, 0, 0, 0),
                color: Colors.black26,
                child: Center(
                  child: ElevatedButton(
                    //미입력된 부분 존재시 넘어가지 못하게 하는 부분 처리 x
                    onPressed: () {
                      fetchSetStoreInfo(
                          widget.id,
                          name,
                          _Store_Name_Controller.text,
                          _Store_Cate_Controller.text,
                          _Store_Desc_Controller.text,
                          entries,
                          enc_images,
                          menus);
                      Navigator.pop(context);
                    },
                    style: ButtonStyle(
                        textStyle: MaterialStateProperty.all(
                            TextStyle(fontSize: 20, color: Colors.white)),
                        backgroundColor:
                            MaterialStateProperty.all(Colors.grey)),
                    child: Text(
                      "입력 완료",
                      style: TextStyle(
                          fontSize: 30,
                          color: Colors.black,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
