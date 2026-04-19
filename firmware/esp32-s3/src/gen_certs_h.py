import os

crt_path = "/Users/andhan/Desktop/Sami/Thamani/Thamani-TinyML/server-deployment/nginx/certs/esp32_client.crt"
key_path = "/Users/andhan/Desktop/Sami/Thamani/Thamani-TinyML/server-deployment/nginx/certs/esp32_client.key"

def format_as_c_string(filepath, var_name):
    with open(filepath, "r") as f:
        lines = f.readlines()
    
    out = f'const char* {var_name} = \n'
    for line in lines:
        line = line.strip()
        out += f'  "{line}\\n"\n'
    out += ';\n'
    return out

with open("/Users/andhan/Desktop/Sami/Thamani/Thamani-TinyML/firmware/esp32-s3/src/certs.h", "w") as f:
    f.write("#ifndef CERTS_H\n#define CERTS_H\n\n")
    f.write(format_as_c_string(crt_path, "client_cert"))
    f.write("\n")
    f.write(format_as_c_string(key_path, "client_priv_key"))
    f.write("\n#endif\n")
