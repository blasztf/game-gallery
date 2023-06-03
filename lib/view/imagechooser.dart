import 'package:flutter/material.dart';
import 'package:mangw/style.dart';
import 'package:mangw/view/gallerypage.dart';

class ImageChooserAdapter extends GalleryPageAdapter<String> {
  ImageChooserAdapter._(this._list, this._onTap);

  factory ImageChooserAdapter(
          {required List<String> list, Function(String)? onItemTap}) =>
      ImageChooserAdapter._(list, onItemTap);

  final List<String> _list;
  final Function(String)? _onTap;

  @override
  String getItem(int index) {
    return _list[index];
  }

  @override
  String getItemImage(int index) {
    return _list[index];
  }

  @override
  int getSize() {
    return _list.length;
  }

  @override
  void onItemTap(String item) {
    _onTap?.call(item);
  }
}

class ImageChooserDialog extends StatelessWidget {
  const ImageChooserDialog(
      {super.key,
      required this.listImage,
      required this.onChosen,
      required this.title});

  final List<String> listImage;
  final Function(String) onChosen;
  final String title;

  final double _spacing = 25.0;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_spacing),
      ),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Column(children: [
        SizedBox(
            child: Container(
          color: mcgpalette0Accent,
          padding: EdgeInsets.all(_spacing),
          width: double.infinity,
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                fontSize: _spacing,
                color: Colors.white,
              ),
            ),
          ),
        )),
        Expanded(
          child: GalleryPage(
            adapter: ImageChooserAdapter(
              list: listImage,
              onItemTap: (data) {
                onChosen(data);
              },
            ),
          ),
        )
      ]),
    );
  }
}
