#!/usr/bin/bash
perl ./Build.PL
perl ./Build installdeps
perl ./Build install
perl ./Build realclean