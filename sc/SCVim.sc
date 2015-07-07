// Copyright 2007 Alex Norman
// with modifications 2008 Dan Stowell
//
// rewritten 2010 - 2012 Stephen Lumenta
//
// This file is part of SCVIM.
//
// SCVIM is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// SCVIM is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with SCVIM.  If not, see <http://www.gnu.org/licenses/>.



/*

SCVim.generateTagsFile();
*/

SCVim {
	classvar nodes, <>vimPath;

	*initClass {
		nodes = List[];

		// TODO this has to be not so mac-centric
		Platform.case(\osx) {

			var whichVim = "which mvim".unixCmdGetStdOut;
			if(whichVim.isEmpty){
				vimPath = "/usr/local/bin/mvim";
			} {
				vimPath = whichVim;
			};
			vimPath = vimPath.replace("\n", "");
		};

		// thanks to Dionysis Athinaios
		StartUp.add { //do after startup has finished
			var classList, file, hugeString = "syn keyword scObject", basePath;

			basePath = "~/.vim/bundle/scvim";

			case
			{ File.exists("~/.vim/bundle/scvim".standardizePath) } { basePath = "~/.vim/bundle/scvim" }
			{ File.exists("~/.vim/bundle/supercollider".standardizePath) } { basePath = "~/.vim/bundle/supercollider" }
			// default case
			{ true } {
				("\nSCVim could not be initialized, please check if the bundle is installed in '~/.vim/bundle/scvim'\n"
					++ "Consult the README how to set up SCVim.\n").error };

					//collect all class names as strings in a Array
					classList =
					Object.allSubclasses.collect{ arg i; var name;
						name = i.asString;
						hugeString = hugeString + name;
					};

					//create a file that contains all the class names
					file = File((basePath ++ "/syntax/supercollider_objects.vim").standardizePath,"w");
					file.write(hugeString);
					file.close;

				};
			}

	*generateTagsFile {
		var tagPath;
		var tagfile;

		tagPath = "SCVIM_TAGFILE".getenv ? "~/.sctags";
		tagPath = tagPath.standardizePath;

		tagfile = File.open(tagPath, "w");

		tagfile.write('!_TAG_FILE_FORMAT	2	/extended format; --format=1 will not append ;" to lines/'.asString ++ Char.nl);
		tagfile.write("!_TAG_FILE_SORTED	2	/0=unsorted, 1=sorted, 2=foldcase/" ++ Char.nl);
		tagfile.write("!_TAG_PROGRAM_AUTHOR	Stephen Lumenta (modified by Dionysis Athinaios) /stephen.lumenta@gmail.com/" ++ Char.nl);
		tagfile.write("!_TAG_PROGRAM_NAME	SCVim.sc//" ++ Char.nl);
		tagfile.write("!_TAG_PROGRAM_URL	https://github.com/sbl/scvim" ++ Char.nl);
		tagfile.write("!_TAG_PROGRAM_VERSION	2.0//" ++ Char.nl);

		Class.allClasses.do {
			arg klass;
			var klassName, klassFilename, klassSearchString,superClassesList, classTreeString= "";
			var lineStringForClasses = "";

			klassName         = klass.asString;
			klassFilename     = klass.filenameSymbol;
			klassSearchString = format("/^%/;\"", klassName);

      /*
      SuperCollider
      c  classes
      m  instance methods
      M  class methods
      */

      superClassesList = List.new;
      klass.superclasses.do{arg i; superClassesList = superClassesList.add(i)};
      classTreeString = classTreeString++ klass.asString ++ ";";
      superClassesList.do{arg i; classTreeString = classTreeString ++ i.asString ++ ";"};

      lineStringForClasses = lineStringForClasses ++ klassName ++ Char.tab;
      lineStringForClasses = lineStringForClasses ++ klassFilename ++ Char.tab;
      lineStringForClasses = lineStringForClasses ++ klassSearchString ++ Char.tab;
      lineStringForClasses = lineStringForClasses ++ "c"  ++ Char.tab;
      lineStringForClasses = lineStringForClasses ++ "class:"++ klassName  ++ Char.tab;
      lineStringForClasses = lineStringForClasses ++ "classTree:" ++ classTreeString++ Char.tab;
      lineStringForClasses = lineStringForClasses ++ "language:supercollider" ++ Char.nl;

			tagfile.write(lineStringForClasses);

      //find and add the instance methods with additional info

			klass.methods.do{|meth|
        var lineStringForInstanceMethods = "";
        var arguments;
				var methName, methFilename, methSearchString;
				methName     = meth.name;
				methFilename = meth.filenameSymbol;
				// this strange fandango dance is necessary for sc to not complain
				// when compiling. 123 is the curly bracket.
				methSearchString = format('/% %/;"'.asString, methName, 123.asAscii);

        if(meth.notNil && meth.argumentString.notNil,
          { var string;
            string = meth.argumentString.replace("this", ""); // .reject({ |c| c.ascii == 32});
            string = string.trim;
            if (string[0].asSymbol == ',', {string.removeAt(0)});
            string = string.trim;
            //need to escape all the symbols that have a special meaning in ctags
            string = string.replace("\n", "'n'").replace("\t", "'t'").replace("\r", "'r'");
            string = string.insert(0, "(");
            string = string.insert(string.size, ")");
            arguments = string;
          }
        );

        lineStringForInstanceMethods = lineStringForInstanceMethods ++ methName ++ Char.tab;
        lineStringForInstanceMethods = lineStringForInstanceMethods ++ methFilename ++ Char.tab;
        lineStringForInstanceMethods = lineStringForInstanceMethods ++ methSearchString ++ Char.tab;
        lineStringForInstanceMethods = lineStringForInstanceMethods ++ "m"  ++ Char.tab;
        lineStringForInstanceMethods = lineStringForInstanceMethods ++ "class:"++ klassName  ++ Char.tab;
        lineStringForInstanceMethods = lineStringForInstanceMethods ++ "classTree:" ++ classTreeString++ Char.tab;
        lineStringForInstanceMethods = lineStringForInstanceMethods ++ "methodArgs:" ++ arguments  ++ Char.tab;
        lineStringForInstanceMethods = lineStringForInstanceMethods ++ "language:supercollider" ++ Char.nl;

        tagfile.write(lineStringForInstanceMethods);
			};

			//find and add the class methods

			klass.metaclass.methods.do{|meth|
        var lineStringForClassMethods = "";
        var arguments;
				var methName, methFilename, methSearchString;
				methName     = meth.name;
				methFilename = meth.filenameSymbol;
				// this strange fandango dance is necessary for sc to not complain
				// when compiling. 123 is the curly bracket.
				methSearchString = format('/% %/;"'.asString, methName, 123.asAscii);

        if(meth.notNil && meth.argumentString.notNil,
          { var string;
            string = meth.argumentString.replace("this", ""); // .reject({ |c| c.ascii == 32});
            string = string.trim;
            if (string[0].asSymbol == ',', {string.removeAt(0)});
            string = string.trim;
            //need to escape all the symbols that have a special meaning in ctags
            string = string.replace("\n", "'n'").replace("\t", "'t'").replace("\r", "'r'");
            string = string.insert(0, "(");
            string = string.insert(string.size, ")");
            arguments = string;
          }
        );

        lineStringForClassMethods = lineStringForClassMethods ++ methName ++ Char.tab;
        lineStringForClassMethods = lineStringForClassMethods ++ methFilename ++ Char.tab;
        lineStringForClassMethods = lineStringForClassMethods ++ methSearchString ++ Char.tab;
        lineStringForClassMethods = lineStringForClassMethods ++ "M"  ++ Char.tab;
        lineStringForClassMethods = lineStringForClassMethods ++ "class:"++ klassName  ++ Char.tab;
        lineStringForClassMethods = lineStringForClassMethods ++ "classTree:" ++ classTreeString++ Char.tab;
        lineStringForClassMethods = lineStringForClassMethods ++ "methodArgs:" ++ arguments ++ Char.tab;
        lineStringForClassMethods = lineStringForClassMethods ++ "language:supercollider" ++ Char.nl;

        tagfile.write(lineStringForClassMethods);
			}
		};

		tagfile.close();

		//get all .sctags lines  apart from the first six. sort them and delete duplicates with result in .sctags.tmp. get the 
		//first six line of .sctags to .sctags_head. combine .sctags head with .sctags.tmp into the result and write it to .sctags
		"tail -n+6 .sctags | sort -f -s -k1 | uniq -u >  .sctags.tmp;head -6 .sctags > .sctags_head.tmp; cat .sctags_head.tmp .sctags.tmp > .sctags_complete.tmp; mv .sctags_complete.tmp .sctags".unixCmd({"rm .sctags_head.tmp; rm .sctags.tmp".unixCmd; "finished generating tagsfile".postln});

	}

} // end class

/* TESTING
testing = Array.new;
another = String.
testing = another

another.realNextName
ekdj.fastResetCamera
Array.fill2D
*/
