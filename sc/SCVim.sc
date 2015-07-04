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

	// DEPRECTATED in favor of tags system
	*openClass{ |klass|
		// TM version only
		var fname, cmd;
		var allClasses = Class.allClasses.collect(_.asString);

		klass = klass.asString;

		if(allClasses.detect{ |str| str == klass }.notNil) { // .includes doesn't work?
			fname = klass.interpret.filenameSymbol;
			cmd = "grep -nh \"^" ++ klass ++ "\" \"" ++ fname ++ "\" > /tmp/grepout.tmp";
			cmd.unixCmd(postOutput: false, action: {
				File.use("/tmp/grepout.tmp", "r") { |f|
					var content = f.readAllString;
					var split = content.split($:);
					if("^[0-9]+$".matchRegexp(split.first.asString)) {
						/*(vimPath ++ " -R \"" ++ fname ++ "\"").unixCmd(postOutput: false);*/
						(vimPath ++ " -R  +"++ split.first + "\"" ++ fname ++ "\"").unixCmd(postOutput: false);
					} {
						(vimPath ++ " -R \"" ++ fname ++ "\"").unixCmd(postOutput: false);
					};
					f.close;
				};
			});
		}{"sorry class "++klass++" not found".postln}
	}

	// DEPRECTATED in favor of tags system
	// TODO improve this to jump to the right implementations even if they are
	// buried in a class extension
	*methodTemplates { |name, openInVIM=true|
		var out, found = 0, namestring, fname;

		name = name.asSymbol;

		out = CollStream.new;
		out << "Implementations of '" << name << "' :\n";
		Class.allClasses.do({ arg class;
			class.methods.do({ arg method;
				if (method.name == name, {

					found = found + 1;
					namestring = class.name ++ ":" ++ name;
					out << "   " << namestring << " :     ";
					if (method.argNames.isNil or: { method.argNames.size == 1 }, {
						out << "this." << name;
						if (name.isSetter, { out << "(val)"; });
					},{
						out << method.argNames.at(0);
						if (name.asString.at(0).isAlpha, {
							out << "." << name << "(";
								method.argNames.do({ arg argName, i;
									if (i > 0, {
										if (i != 1, { out << ", " });
										out << argName;
									});
								});
								out << ")";
							},{
								out << " " << name << " ";
								out << method.argNames.at(1);
							});
						});
						out.nl;
					});
				});
			});
			if(found == 0)
			{
				Post << "\nNo implementations of '" << name << "'.\n";
			}
			{
				if(openInVIM) {
					fname = "/tmp/" ++ Date.seed ++ ".sc";
					File.use(fname, "w") { |f|
						f << out.collection.asString;
						(vimPath + fname).unixCmd(postOutput: false);
					};
				};
			};
	}

	// DEPRECTATED in favor of tags system
	*methodReferences { |name, openInVIM=true|
		var out, references, fname;
		name = name.asSymbol;
		out = CollStream.new;
		references = Class.findAllReferences(name);

		if (references.notNil, {
			out << "References to '" << name << "' :\n";
			references.do({ arg ref; out << "   " << ref.asString << "\n"; });

			if(openInVIM) {
				fname = "/tmp/" ++ Date.seed ++ ".sc";
				File.use(fname, "w") { |f|
					f << out.collection.asString;
					(vimPath + "-R" + fname).unixCmd(postOutput: false);
				};
			} {
				out.collection.newTextWindow(name.asString);
			};
		},{
			Post << "\nNo references to '" << name << "'.\n";
		});
	}

	*generateTagsFile {
		var tagPath;
		var tagfile;

		tagPath = "SCVIM_TAGFILE".getenv ? "~/.sctags";
		tagPath = tagPath.standardizePath;

		tagfile = File.open(tagPath, "w");

		tagfile.write('!_TAG_FILE_FORMAT	2	/extended format; --format=1 will not append ;" to lines/'.asString ++ Char.nl);
		tagfile.write("!_TAG_FILE_SORTED	1	/0=unsorted, 1=sorted, 2=foldcase/" ++ Char.nl);
		tagfile.write("!_TAG_PROGRAM_AUTHOR	Stephen Lumenta (modified by Dionysis Athinaios) /stephen.lumenta@gmail.com/" ++ Char.nl);
		tagfile.write("!_TAG_PROGRAM_NAME	SCVim.sc//" ++ Char.nl);
		tagfile.write("!_TAG_PROGRAM_URL	https://github.com/sbl/scvim" ++ Char.nl);
		tagfile.write("!_TAG_PROGRAM_VERSION	2.0//" ++ Char.nl);

		Class.allClasses.do {
			arg klass;
			var klassName, klassFilename, klassSearchString, superClassesArray, superClassesString = "";
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

      /*
      //to get class methods I need to use Meta_SinOsc
      Meta_SinOsc.findRespondingMethodFor(\ar).argumentString;
      //For istance methods just use the normal one
      Array.findRespondingMethodFor(\sort).argumentString;

      SinOsc.arj
      Array.fib
      Collection.
      fdfkj.fastAtL
      */

      superClassesArray = klass.superclasses;
      superClassesArray.do{arg i; superClassesString = superClassesString ++ i.asString ++ ";"};

      lineStringForClasses = lineStringForClasses ++ klassName ++ Char.tab;
      lineStringForClasses = lineStringForClasses ++ klassFilename ++ Char.tab;
      lineStringForClasses = lineStringForClasses ++ klassSearchString ++ Char.tab;
      lineStringForClasses = lineStringForClasses ++ "c"  ++ Char.tab;
      lineStringForClasses = lineStringForClasses ++ "class:"++ klassName  ++ Char.tab;
      lineStringForClasses = lineStringForClasses ++ "superclasses:" ++ superClassesString ++ Char.tab;
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
          {
            //need to escape all the symbols that have a special meaning in ctags
            arguments = meth.argumentString.replace("\n", "'n'").replace("\t", "'t'").replace("\r", "'r'") .replace("this", "").reject({ |c| c.ascii == 32})++";"
          }
        );

        /* ARHeadtracker.class.methods.do{arg i; i.name.postln}; */
        /* ARHeadtracker.class.findRespondingMethodFor('new').argumentString.replace(",", ";").replace("this", "").reject({ |c| c.ascii == 32})++";"; */

        lineStringForInstanceMethods = lineStringForInstanceMethods ++ methName ++ Char.tab;
        lineStringForInstanceMethods = lineStringForInstanceMethods ++ methFilename ++ Char.tab;
        lineStringForInstanceMethods = lineStringForInstanceMethods ++ methSearchString ++ Char.tab;
        lineStringForInstanceMethods = lineStringForInstanceMethods ++ "m"  ++ Char.tab;
        lineStringForInstanceMethods = lineStringForInstanceMethods ++ "class:"++ klassName  ++ Char.tab;
        lineStringForInstanceMethods = lineStringForInstanceMethods ++ "superclasses:" ++ superClassesString ++ Char.tab;
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
          {
            arguments = meth.argumentString.replace("\n", "'n'").replace("\t", "'t'").replace("\r", "'r'") .replace("this", "").reject({ |c| c.ascii == 32})++";"
          }
        );

        lineStringForClassMethods = lineStringForClassMethods ++ methName ++ Char.tab;
        lineStringForClassMethods = lineStringForClassMethods ++ methFilename ++ Char.tab;
        lineStringForClassMethods = lineStringForClassMethods ++ methSearchString ++ Char.tab;
        lineStringForClassMethods = lineStringForClassMethods ++ "M"  ++ Char.tab;
        lineStringForClassMethods = lineStringForClassMethods ++ "class:"++ klassName  ++ Char.tab;
        lineStringForClassMethods = lineStringForClassMethods ++ "superclasses:" ++ superClassesString ++ Char.tab;
        lineStringForClassMethods = lineStringForClassMethods ++ "methodArgs:" ++ arguments ++ Char.tab;
        lineStringForClassMethods = lineStringForClassMethods ++ "language:supercollider" ++ Char.nl;

        tagfile.write(lineStringForClassMethods);
			}
		};

		tagfile.close();
		//sorting the file allows vim to do binary search
		"sort -f -s -k1.1,1.1 .sctags > .sctags.tmp; mv .sctags.tmp .sctags".unixCmd({"finished generating tagsfile".postln});
	}
} // end class
