import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:spartial/screens/settings.dart';
import 'package:spartial/widgets/buttons.dart';
import 'package:spartial/services/storage.dart';

/// Screen that shows that the storage is full.
class StorageLimitReachedPage extends StatefulWidget {
  const StorageLimitReachedPage({Key? key}) : super(key: key);

  @override
  _StorageLimitReachedPageState createState() =>
      _StorageLimitReachedPageState();
}

class _StorageLimitReachedPageState extends State<StorageLimitReachedPage> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: SingleChildScrollView(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
            Row(
              children: [
                IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: Icon(
                      Icons.arrow_back,
                      color: Theme.of(context).highlightColor,
                    )),
              ],
            ),
            Padding(
              padding: EdgeInsets.all(60.sp),
              child: Center(
                child: Column(
                  children: [
                    Text(
                      "Storage limit reached!",
                      style: Theme.of(context).textTheme.headline2,
                    ),
                    SizedBox(
                      height: 60.h,
                    ),
                    Text(
                      "Damn you've added a lot of songs already!",
                      style: Theme.of(context).textTheme.subtitle1,
                      maxLines: 2,
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(
                      height: 20.h,
                    ),
                    Text(
                      "Unfortunately you've reached the storage limit, you can either remove some songs or consider expanding the storage.",
                      style: Theme.of(context).textTheme.subtitle1,
                      maxLines: 4,
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(
                      height: 60.h,
                    ),
                    Text(
                      "Upgrade storage capacity to a ${Storage.getNextStorageUpgradeCapacity()} songs:",
                      style: Theme.of(context).textTheme.subtitle2,
                    ),
                    SizedBox(
                      height: 24.h,
                    ),
                    SolidRoundedButton(
                        onPressed: () {},
                        text:
                            "Expand storage for € ${Storage.getNextStorageUpgradePrice()}"),
                    SizedBox(
                      height: 30.h,
                    ),
                    Text(
                      "or",
                      style: Theme.of(context).textTheme.subtitle2,
                      maxLines: 2,
                      textAlign: TextAlign.center,
                    ),
                    TextButton(
                        onPressed: () {
                          Navigator.pushReplacement<void, void>(
                            context,
                            MaterialPageRoute<void>(
                              builder: (BuildContext context) =>
                                  const SettinsPage(
                                highlightStorage: true,
                              ),
                            ),
                          );
                        },
                        child: Text(
                          "See other storage upgrade options",
                          style: Theme.of(context).textTheme.headline6,
                        )),
                    Text(
                      "or",
                      style: Theme.of(context).textTheme.subtitle2,
                      maxLines: 2,
                      textAlign: TextAlign.center,
                    ),
                    TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: Text(
                          "Remove some songs",
                          style: Theme.of(context).textTheme.headline6,
                        ))
                  ],
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
