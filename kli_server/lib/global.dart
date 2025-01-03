import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:kli_lib/kli_lib.dart';
import 'package:side_navigation/side_navigation.dart';

bool isTesting = kDebugMode, showDebugInfo = false;
late final DecorationImage bgDecorationImage;
final buildDate = DateTime(2024, 10, 28);

void Function() updateDebugOverlay = () {};
late void Function() updateChild;

late final LogHandler logHandler;
late final String appVersionString;
late final StorageHandler storageHandler;
late final AudioHandler audioHandler;
late final AssetHandler assetHandler;

AppBar managerAppBar(
  BuildContext context,
  String title, {
  Widget? leading,
  bool implyLeading = false,
  List<Widget>? actions,
  final double fontSize = fontSizeXL,
}) {
  return AppBar(
    title: Text(title),
    leading: leading,
    backgroundColor: Colors.transparent,
    automaticallyImplyLeading: implyLeading,
    titleTextStyle: TextStyle(fontSize: fontSize),
    centerTitle: true,
    surfaceTintColor: Colors.transparent,
    toolbarHeight: kToolbarHeight * 1.1,
    actions: actions,
  );
}

Widget matchSelector(List<String> matchNames, void Function(String?) onSelected) {
  return DropdownMenu(
    label: const Text('Trận đấu'),
    dropdownMenuEntries: [
      for (var i = 0; i < matchNames.length; i++)
        DropdownMenuEntry(
          value: matchNames[i],
          label: matchNames[i],
        )
    ],
    onSelected: onSelected,
  );
}

/// A custom ListTile with variable column count and an optional delete button.<br>
/// The columns are defined by a pair/record ```(content: Widget, widthRatio: double)```.
Widget customListTile(
  BuildContext context, {
  required List<(Widget, double)> columns,
  void Function()? onTap,
}) {
  return MouseRegion(
    cursor: onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
    child: InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.only(left: 16, right: 24, top: 24, bottom: 24),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(width: 2, color: Theme.of(context).colorScheme.onBackground),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (final (child, ratio) in columns)
              SizedBox(
                width: MediaQuery.of(context).size.width * ratio.clamp(0, 1),
                child: child is Text ? _applyFontSize(child) : child,
              ),
          ],
        ),
      ),
    ),
  );
}

Text _applyFontSize(Text t) {
  return Text('${t.data}', textAlign: t.textAlign, style: const TextStyle(fontSize: fontSizeMedium));
}

SideNavigationBarTheme sideNavigationTheme(BuildContext context, [double height = 2]) {
  return SideNavigationBarTheme(
    itemTheme: SideNavigationBarItemTheme(
      selectedItemColor: Theme.of(context).colorScheme.primary,
      labelTextStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: fontSizeMSmall, height: height),
    ),
    togglerTheme: SideNavigationBarTogglerTheme.standard(),
    dividerTheme: const SideNavigationBarDividerTheme(
      showHeaderDivider: true,
      headerDividerColor: Color(0x64FFFFFF),
      showMainDivider: true,
      showFooterDivider: false,
    ),
  );
}

class DataSize {
  static int matchActualDataSize = 0;
  static int matchMessageSize = 0;

  static int playerActualDataSize = 0;
  static int playerMessageSize = 0;
}

const String changelog = """
  0.4.6.1 ({latest}):
  - Added confirmation to end section
  - Removed some async calls
  - Fixed can get next extra question after end
  - Fixed wrong extra background audio length

  0.4.6 ({2df09fb}):
  - Translated all text to Vietnamese
  - Added help for match control
  - Fixed some help text
  - Sound page is above log
  - Fixed extra requires at least 3 questions instead of 1
  - Prepare to files for alternative data transfer

  0.4.5.6 ({486a5bb}):
  - Reworked DataManager
  - Saved data is now separated by match name
  - Some short text input is now limited to 1 line
  - Fixed play audio message is sent to MC

  0.4.5.5 ({2c329e0}):
  - Highlights players participating in Extra
  - Sends who participating in Extra to clients
  - Missing dev state update in match screens
  - Added section result screen
  - Added sounds for match

  0.4.5.4 ({035ee5d}):
  - Added Debug overlay: version, build date, test mode, server status, host IP, port, device IP...
  - Can start match with no player
  - Finish manager shows which question has video
  - Back buttons also pops client-side routes
  - Added 'Show rows' to Obstacle & Accel screen: shows rows on viewer screen
  - Changed folder name to snake_case
  - The host IP can be selected to copy

  0.4.5.3 ({085715f}):
  - Added video player to Finish UI: hides question, shows video & answer
  - Fixed receiving error showing concatenated data while already handled

  0.4.5.2 ({cf809e4}):
  - Show arrange question's answer when pressing explanation button
  - Fixed can select and start question when obstacle is answered
  - Finish point values are selected first, then use side buttons to show next question
  - Select star before showing question, can only use once
  - Stealing shows other who's the stealer
  - Wrong answer with star reduces score (original value), won't be reduced again if stolen
  - Fixed player scores can be negative
  - Extra section receives player answer signals
  - Added "dialog" to allow 2-4 players to participate in extra section
  - Manager app bar can have custom leading
  - Match can end or continue with the Extra section, players not in extra can exit right away

  0.4.5.1 ({463fdf9}):
  - Fixed accel manager not showing type when image count is 0
  - Accel manager allows adding multiple images at once, but result is sorted
  - Fixed out of range when switching image too fast
  - Fixing null IP address when using Ethernet
  - Send playerData if player requested, send matchData if viewer/mc requested
  - Fixed invalid url when opening app folder

  0.4.5 ({aeaa769}):
  - Added Extra UI: question, answer, timer, stop timer
  - Added extra scores for sort players with same scores
  - Match Data Checker only take the required match, not all
  - Fixed several missing 'setState's after starting the timer
  - Removed some 'mounted' checks

  0.4.4 ({e8abe73}):
  - Added Finish UI: question, answer, timer, explanation, star, point value
  - Some question info (e.g. question number, subject) now shows in the corner instead
  - Shows player names & scores in section screens instead of question info
  - Fixed missing 'setState's in Obstacle
  - Answer drawer now shows player scores
  - Fixed starting Obstacle timer after wrong obstacle guess while no question is selected
  - Fixed not changing to Acceleration when obstacle is guessed correctly

  0.4.3 ({79f968c}):
  - Added Accel UI: question, answer, timer, image(s), player answers, explanation
  - Send all match data: data size, names, images, videos to clients when requested

  0.4.2 ({363f0c6}):
  - Obstacle improvements: received/show answers and obs guesses, properly send points, keep track of eliminated, scores, ans results...
  - Some errors show a popup message
  - Some routes are replaced
  - Global error handling using PlatformDispatcher, widget error screen now show stack, can turn back
  - SoundTest screen no longer requires globals as params
  - Fixed cut error title
  - Initialize MatchState in data checker
  - Show ready status for players (may revert)
  - Properly cancel streams when disposing
  - Start questions are shuffled

  0.4.1 ({cfc575a}):
  - Start match button enabled when players are ready (only 1 needed if debug)
  - Moved ObstacleRow to lib
  - Reverted start pos check after start
  - Send stopTimer message if all timer not finished but done already
  - Now save PackageInfo (version) as string

  0.4 ({34c61cd}):
  - Added error message to loading screen
  - Added overview UI: name, players, scores, current section, timer
  - Added Start UI: question, answer, timer, subject, question count
  - Added Obstacle UI: (correctly/wrongly answered) questions, answer, player answers, timer, image, image covers
  - Can receive Player info request from clients and respond
  - Receives and sends ready signal from/to players, can only start match if all is ready
  - Fixed wrong log messages
  - All player pos is now 0-based

  0.3.2.1 ({de8a02f}):
  - Updated KLI Lib to 0.4
  - Extracted repeating manager methods to generics
  - Added sound test page
  - Added 'feature' that allows user to manage background image and sounds
  - Added help menu to Data Managers
  
  0.3.2 ({c2fb3d0}):
  - Added Loading screen
  - Can now delete shared background
  - Fixed client list wrong IP and port
  - Fixed more log messages

  0.3.1.3 ({aa2a188}):
  - Now uses LogHandler for logging
  - Logs version on launch
  - Better log messages & nested log
  - Added background manager
  - Uses shared background hosted online, else default background
  - Better client list in Server Setup

  0.3.1.2 ({e50b469}):
  - Disabled light theme (like who need this anyway)
  - Use less theme colors
  - Can use 'Esc' to quickly exit page
  - Fixed background images is a little dim
  - Added Start match button after all player joined

  0.3.1.1 ({8541f82}):
  - Assets moved to KLILib
  - Added more tooltips to buttons
  - Better data checker error for start question display
  - Added iconButton custom widget (similar to other buttons)
  - Checks Accel image errors better

  0.3.1 ({8e8f615}):
  - Renamed data manager pages
  - Match data checker page: check if all info are good, show errors if not

  0.3 ({3fbfae0}):
  - Improved Server Setup UI
  - Fixed stream controller not re-opened after restarting server
  - Added disconnect message type
  - Can no longer start/stop server when there is/isn't a running server
  - Reworked Client ID
  - Can disconnect individual client
  - Disconnect all clients when stopping server

  0.2.8.3 ({47176ce}):
  - Added changelog & changelog view in app
  - Changed help screen layout to avoid overflow on launch
  - Added 'Licenses' button in changelog

  0.2.8.2 ({8491f11}):
  - Trim all text input fields
  - Import preview line spacing
  - Named parameters consistency

  0.2.8.1 ({c858fb4}):
  - Changed all save files to json
  - Notify on errors where applicable

  0.2.8 ({f06065d}):
  - Added preview window for importing data -> can check for errors in data
  - Added obstacle editor (NOT obstacle QUESTION editor)

  0.2.7.1 ({dc7ecea}):
  - Only enable editor 'Done' when all required fields is filled
  - Fixed changing match name delete all of its saved questions

  0.2.7 ({f41ab9c}):
  - Added "localization"
  - Added accel question type
  - Better confirm dialog

  0.2.6.3 ({34330ac}):
  - Added confirm dialog when deleting questions
  - Backend changes: early returns, save files structure
  - Shortened some messages
  - Log message has time
  - Button to open app folder, instruction file, log file

  0.2.6.2 ({7096e17}):
  - Generics for question managers
  - New background image
  - Ensure window only show after forced fullscreen
  - Added exit button in start screen

  0.2.6.1 ({4e00f85}):
  - Help screen is first/default page in start screen

  0.2.6 ({6b65e46}):
  - Added help screen
  - Storage handler excel reader: limit sheet count
  
  0.2.5 ({119b134}):
  - Added feature to add singular start question
  - Fixed manager bug related to nullable
  - Added acceleration question manager
  - Minor fixes: match manager background, can't add start question, wrong log messages

  0.2.4 ({e155b1c}):
  - Better seekbar for finish question video
  - Notify if media file isn't found at specified path
  - Extra question manager
  - Changed sdk lower bound: 2.19.6 -> 3.0 (record/pattern)
  - Better custom list tile for question lists

  0.2.3 ({2cb1ac7}):
  - Finish question video rework: change lib, can remove
  - Output log in release build
  - Updated data manager background

  0.2.2 ({2eea3c9}):
  - Wrap Start questions in a match
  - Log output to file, even from kli_lib
  - Added finish question manager
  - Change log file location

  0.2.1 ({5f21bdf}):
  - Obstacle question manager: wrap questions in a match

  0.2 ({e8fc93f}):
  - Added Match manager: match name, players
  - Added Start question manager: question list, add/edit/remove
  - App theme, icon
  - Better storage handler: init folders/files, read/write file

  0.1.x ({333b4f3}):
  - Added basic messaging (with utf8)
  - Basic setup for data manager: UI
  - Added LogHandler: logs to console
  - Added basic start screen: side navigation, app version
  - Added storage handler: read excel, write to file
  - Force fullscreen on launch

  0.0.1.x ({d9628a9}):
  - Initial version -> setup workspace
  - Added basic server setup & server-client connection""";
