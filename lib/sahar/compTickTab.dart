import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:tadhkiratrack/widgets/companies/company.dart';
import 'package:tadhkiratrack/widgets/companies/row_tick_header.dart';

class PnlTckViewer extends StatelessWidget {
  final Company cmp;
  const PnlTckViewer({Key? key, required this.cmp}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color.fromARGB(255, 174, 176, 179),
      width: 650,
      height: 100,
      child: Column(
        children: [
          RowTickHeader(),
          Container(
            child: Scrollbar(
              child: ListView(
                children: [
                  Center(
                    child: Container(
                      width: 600,
                      height: 300,
                      color: Colors.black12,
                      child: Center(
                        child: Scrollbar(
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: [
                              RowTickHeader(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
