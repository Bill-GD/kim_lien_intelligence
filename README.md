# kim_lien_intelligence

![GitHub repo size](https://img.shields.io/github/repo-size/Bill-GD/kim_lien_intelligence?style=plastic) ![GitHub repo size](https://img.shields.io/github/languages/code-size/Bill-GD/kim_lien_intelligence?style=plastic)  
[![wakatime](https://wakatime.com/badge/github/Bill-GD/kim_lien_intelligence.svg)](https://wakatime.com/badge/github/Bill-GD/kim_lien_intelligence)  
[![wakatime](https://wakatime.com/badge/github/Bill-GD/kli_lib.svg)](https://wakatime.com/badge/github/Bill-GD/kli_lib) &rarr; Different workspace

![Dynamic YAML Badge](https://img.shields.io/badge/dynamic/yaml?url=https%3A%2F%2Fraw.githubusercontent.com%2FBill-GD%2Fkim_lien_intelligence%2Frefs%2Fheads%2Fmain%2Fkli_server%2Fpubspec.yaml&query=version&prefix=v&label=KLIServer)
![Dynamic YAML Badge](https://img.shields.io/badge/dynamic/yaml?url=https%3A%2F%2Fraw.githubusercontent.com%2FBill-GD%2Fkim_lien_intelligence%2Frefs%2Fheads%2Fmain%2Fkli_client%2Fpubspec.yaml&query=version&prefix=v&label=KLIClient)



A set of 2 apps. The library is private.  
Date created: 01/04/2024

## KLI Server

- Handle questions
  - Show/view, add, modify, delete questions
- Handle matches
  - Show/view (?), add, modify, delete matches
- Handle host/server
  - Handle client connections
  - Handle & Sync match state

## KLI Client

- For contestants
- Connects to host using host IP (local only)
- Uses match state info form Server to display corresponding screens
