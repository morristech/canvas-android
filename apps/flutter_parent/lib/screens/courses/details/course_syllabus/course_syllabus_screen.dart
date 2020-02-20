// Copyright (C) 2019 - present Instructure, Inc.
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, version 3 of the License.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_parent/screens/courses/details/course_details_model.dart';
import 'package:flutter_parent/screens/courses/details/course_syllabus/course_syllabus_interactor.dart';
import 'package:flutter_parent/utils/common_widgets/simple_webview_screen.dart';
import 'package:flutter_parent/utils/quick_nav.dart';
import 'package:flutter_parent/utils/service_locator.dart';
import 'package:flutter_parent/utils/web_view_utils.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';

class CourseSyllabusScreen extends StatefulWidget {
  final String _syllabus;
  final String _courseName;
  CourseSyllabusScreen(this._syllabus, this._courseName);

  @override
  _CourseSyllabusScreenState createState() => _CourseSyllabusScreenState();
}

class _CourseSyllabusScreenState extends State<CourseSyllabusScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required super call for AutomaticKeepAliveClientMixin
    CourseDetailsModel.selectedTab = 1;
    return Consumer<CourseDetailsModel>(
      builder: (context, model, _) => WebView(
        javascriptMode: JavascriptMode.unrestricted,
        gestureRecognizers: Set()..add(Factory<WebViewGestureRecognizer>(() => WebViewGestureRecognizer())),
        onWebViewCreated: (controller) {
          controller.loadHtml(widget._syllabus, horizontalPadding: 10);
        },
        navigationDelegate: (NavigationRequest request) async {
          // TODO: Wire in routing here when it's ready
          String url = await locator.get<CourseSyllabusInteractor>().getUrl(request.url);

          locator.get<QuickNav>().push(context, SimpleWebViewScreen(url, widget._courseName));
          return NavigationDecision.prevent;
        },
      ),
    );
  }
}