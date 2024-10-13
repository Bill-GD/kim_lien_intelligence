#include <iostream>
#include <string>
#include <windows.h>
#include <fstream>
#include <direct.h>

using namespace std;

bool dir_exists(string path) {
  // return GetFileAttributes(path.c_str()) & FILE_ATTRIBUTE_DIRECTORY;
  DWORD dwAttrib = GetFileAttributes(path.c_str());

  return (dwAttrib != INVALID_FILE_ATTRIBUTES &&
    (dwAttrib & FILE_ATTRIBUTE_DIRECTORY));
}

void copy_dir(string src, string dest) {
  WIN32_FIND_DATA ffd;
  HANDLE hFind = FindFirstFile((src + "\\*").c_str(), &ffd);

  if (hFind == INVALID_HANDLE_VALUE) {
    cout << "Could not open directory" << endl;
    return;
  }
  else {
    do {
      if (strcmp(ffd.cFileName, ".") != 0 && strcmp(ffd.cFileName, "..") != 0) {
        ifstream src_file(src + "\\" + ffd.cFileName, ios::binary);
        ofstream dest_file(dest + "\\" + ffd.cFileName, ios::binary);
        dest_file << src_file.rdbuf();
        src_file.close();
        dest_file.close();
      }
    } while (FindNextFile(hFind, &ffd) != 0);
    FindClose(hFind);
  }
}

int main() {
  cout << "Setup SampleMatch" << endl;

  string cache_path = (string)getenv("LOCALAPPDATA") + "\\bill_gd\\kli_client";
  cout << "Local AppData: " << cache_path << endl;

  char app_dir[100];
  GetCurrentDirectory(100, app_dir);
  cout << "Current directory: " << app_dir << endl << endl;

  string sample_media = app_dir + (string)"\\Sample\\media",
    sample_saved = app_dir + (string)"\\Sample\\saved_data";

  cout << "Sample data directories:" << endl;
  cout << " > Media: " << sample_media << endl;
  cout << " > Saved data: " << sample_saved << endl << endl;

  cout << "Setting up server data" << endl;
  if (!dir_exists(sample_media) || !dir_exists(sample_saved)) {
    cout << " > At least one of the sample data directories is missing." << endl;
    cout << " > If this is the client setup, ignore. Else, something is wrong." << endl;
  }
  else {
    string dest_media = app_dir + (string)"\\user_data\\media",
      dest_saved = app_dir + (string)"\\user_data\\saved_data";

    if (!dir_exists(dest_media)) {
      _mkdir(dest_media.c_str());
    }
    if (!dir_exists(dest_saved)) {
      _mkdir(dest_saved.c_str());
    }

    copy_dir(sample_media, dest_media);
    cout << " > Media files copied." << endl;
    copy_dir(sample_saved, dest_saved);
    cout << " > Saved data copied." << endl;
  }


  string sample_cache_other = app_dir + (string)"\\Sample\\SampleMatch\\other",
    sample_cache_player = app_dir + (string)"\\Sample\\SampleMatch\\player";

  cout << endl << "Sample cache directories:" << endl;
  cout << " > Other: " << sample_cache_other << endl;
  cout << " > Player: " << sample_cache_player << endl << endl;

  cout << "Setting up server data" << endl;

  string dest_parent = cache_path + "\\SampleMatch",
    dest_other = dest_parent + "\\other",
    dest_player = dest_parent + "\\player";

  if (!dir_exists(dest_parent)) {
    _mkdir(dest_parent.c_str());
  }
  if (!dir_exists(dest_other)) {
    _mkdir(dest_other.c_str());
  }
  if (!dir_exists(dest_player)) {
    _mkdir(dest_player.c_str());
  }

  copy_dir(sample_cache_other, dest_other);
  cout << " > Cache other files copied." << endl;
  copy_dir(sample_cache_player, dest_player);
  cout << " > Cache player files copied." << endl;

  ofstream cache_file(cache_path + "\\cache.txt");
  cache_file << "The folder(s) here are used for caching match data (names, images, videos) so that the client app doesn't need to request new data every time joining a match." << endl << endl;
  cache_file << "If the data is changed, it'll still need to request new data.";

  cout << endl << "Setup complete." << endl;

  cache_file.close();

  getchar();
}