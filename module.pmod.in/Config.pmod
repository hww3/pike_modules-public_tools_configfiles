//! A class for reading and writing "ini" style files.

/* Config file reader/writer
   Copyright 1998 by Bill Welliver
   hww3@riverweb.com
   
   This file may be used and distributed under the terms of the 
   GNU Public License version 2 or later.

*/

//!
string format_section(string section, mapping attributes){
//  perror(section + ":\n" + sprintf("%O", attributes));
  string s="";
  
  s+="\n[" + section + "]\n";
  foreach(indices(attributes), string a) {
//        perror("attribute " + a + ", value " +attributes[a] +" \n");
       if(arrayp(attributes[a]))
            foreach(attributes[a], string v)
            s+=a + "=" + v + "\n";
        else s = s + a + "=" + (string)attributes[a] + "\n";
      }
  return s;

}

//! converts an ini-file string into a mapping of section names
//! to section configuration contents.
//!
//! a section name must be unique within a given file, however
//! a section may contain multiple entries with the same key. in
//! such a situation, the key will point to an array containing the
//! values in the order in which they were encountered in the 
//! configuration file.
//!
//! @param contents
//!   a string containing the contents of an ini file.
//!
mapping read(string contents){
    mapping config=([]);
    string section,attribute,value;
    array c;
    if(contents)
    {
      contents = replace(contents, ({"\r\n", "\r"}), ({"\n", ""}));
      c=contents/"\n";
    }
    else return ([]); 
    foreach(c, string line) {
        if(!sizeof(line) || line[0] == '#') continue;
        if((line-" ")[0..0]=="[") { // We've got a section header
            sscanf(line,"%*s[%s]%*s",section);
            if(!config[section])
                config[section]=([]);
        }
        if(sscanf(line,"%s=%s", attribute, value)==2) // attribute line.
            if(config[section][attribute] && arrayp(config[section][attribute]))
                config[section][attribute]+=({value});
            else if(config[section][attribute])
                config[section][attribute]=({config[section][attribute]}) + ({value});
            else config[section][attribute]=value;
    }
    return config;
}

//! formats a configuration mapping, such as one produced by @[read],
//! into the ini file format. 
//!
//! @param config
//!  the configuration mapping
//!
//! @param order
//!   an optional array containing section names in the order in which 
//!   they should be added to the resulting string.
//!
//! @returns
//!   a string in the ini file format.
//!
string write(mapping config, array|void order){
    string s="# Configuration file.\n";
    array configs;
    if(!config) return s;
//perror(sprintf("%O", config));
    if(order) configs=order;
    else configs=indices(config);
    foreach(configs, string c){
//      perror("formatting section " + c + "\n");
//      perror("section values:\n " + sprintf("%O", config[c]) + "\n");

      s+= format_section(c, config[c]) +"\n";
    }

    return s;
}

//! get a list of configuration sections from an ini formatted string
//!
//! @param contents
//!  a string containing an ini-formatted string
//!
array get_section_names(string contents){
array sections=({});

array c=contents/"\n";
string section="";

foreach(c, string line) {
  if(sscanf(line, "[%s]", section)==1)
    sections +=({section});
  }
return sections;

}

//! writes a section to a configuration file, replacing the corresponding 
//! section, if it exists. makes a backup of the old file before writing
//! the new file. note that this method will remove any existing comments
//! or formatting from the file on disk.
//!
//! @param file
//!   the name of the file to read/write
//!
//! @param section
//!   the name of the section to write
//!
//! @param attributes
//!   the section of configuration to write.
//!
int write_section(string file, string section, mapping attributes){


  if(!(file || !section || !attributes))
    return -1;	// no information was provided.

  mapping cpy=read(Stdio.read_file(file));


  cpy[section]=attributes;

  mv(file, file+"~");

  Stdio.write_file(file, write(cpy));
  return 0;

}
