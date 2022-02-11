import 'package:flutter/material.dart';
import 'package:spartial/services/logger.dart';
import 'package:spartial/services/settings.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:spartial/widgets/buttons.dart';
import 'package:url_launcher/url_launcher.dart';

// Input for client ID
class ClientIDInput extends StatefulWidget {
  final Function onChanged;
  const ClientIDInput({Key? key, required this.onChanged}) : super(key: key);

  @override
  _ClientIDInputState createState() => _ClientIDInputState();
}

class _ClientIDInputState extends State<ClientIDInput> {
  /// The value of the client id input.
  String clientIDInputValue = Settings.clientID();
  final TextEditingController controller =
      TextEditingController(text: Settings.clientID());

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Client ID",
          style: Theme.of(context).textTheme.subtitle1,
        ),
        SizedBox(
          height: 12.h,
        ),
        Row(
          children: [
            Expanded(
                child: TextFormField(
              autofocus: false,
              maxLength: 50,
              controller: controller,
              cursorColor: Theme.of(context).colorScheme.secondary,
              style: Theme.of(context).textTheme.headline3,
              decoration: InputDecoration(
                  isDense: true,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 30.w, vertical: 30.h),
                  hintStyle: Theme.of(context).textTheme.subtitle1,
                  focusColor: Colors.white,
                  focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                          color: clientIDInputValue.length == 32
                              ? Theme.of(context).colorScheme.secondary
                              : Colors.red)),
                  enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                          color: clientIDInputValue.length == 32
                              ? Theme.of(context).colorScheme.secondary
                              : Colors.red)),
                  hintText: 'Client ID',
                  counterText: ''),
              onChanged: (String value) {
                setState(() {
                  clientIDInputValue = value;
                });
                widget.onChanged(value);
              },
            )),
            SizedBox(
              width: 24.w,
            ),
            SolidRoundedButton(
              onPressed: () {
                setState(() {
                  Settings.setClientID(Settings.defaultClientID);
                  clientIDInputValue = Settings.defaultClientID;
                  controller.text = Settings.defaultClientID;
                  widget.onChanged(Settings.defaultClientID);
                });
              },
              text: "Reset",
              backGroundColor: Theme.of(context).colorScheme.secondary,
            ),
          ],
        ),
        TextButton(
            style: TextButton.styleFrom(
                padding: EdgeInsets.zero, alignment: Alignment.centerLeft),
            onPressed: () async {
              try {
                await launch("https://spartial.app/setup");
              } on Exception catch (e) {
                Logger.error(e);
              }
            },
            child: Text(
              "What is this client ID?",
              style: Theme.of(context).textTheme.headline6,
            ))
      ],
    );
  }
}
