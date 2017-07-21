# NAME

[CPAN::Mini::Inject](https://metacpan.org/pod/CPAN::Mini::Inject) - Inject modules into a [CPAN::Mini](https://metacpan.org/pod/CPAN::Mini) mirror.

# VERSION

Version 0.33

# Synopsis

If you're not going to customize the way CPAN::Mini::Inject works you
probably want to look at the [mcpani](https://metacpan.org/pod/mcpani) command instead.

```perl
use CPAN::Mini::Inject;

$mcpi=CPAN::Mini::Inject->new;
$mcpi->parsecfg('t/.mcpani/config');

$mcpi->add( module   => 'CPAN::Mini::Inject',
            authorid => 'SSORICHE',
            version  => ' 0.01',
            file     => 'mymodules/CPAN-Mini-Inject-0.01.tar.gz' )

$mcpi->writelist;
$mcpi->update_mirror;
$mcpi->inject;
```

# DESCRIPTION

[CPAN::Mini::Inject](https://metacpan.org/pod/CPAN::Mini::Inject) uses [CPAN::Mini](https://metacpan.org/pod/CPAN::Mini) to build or update a local CPAN mirror
then adds modules from your repository to it, allowing the inclusion
of private modules in a minimal CPAN mirror.

# METHODS

Each method in CPAN::Mini::Inject returns a CPAN::Mini::Inject object which
allows method chaining. For example:

```perl
my $mcpi=CPAN::Mini::Inject->new;
$mcpi->parsecfg
     ->update_mirror
     ->inject;
```

A `CPAN::Mini::Inject` ISA [CPAN::Mini](https://metacpan.org/pod/CPAN::Mini). Refer to the
[documentation](https://metacpan.org/pod/CPAN::Mini) for that module for details of the interface
`CPAN::Mini::Inject` inherits from it.

- `new`

    Create a new CPAN::Mini::Inject object.

- `config_class( [CLASS] )`

    Returns the name of the class handling the configuration.

    With an argument, it sets the name of the class to handle
    the config. To use that, you'll have to call it before you
    load the configuration.

- `config`

    Returns the configuration object. This object should be from
    the class returned by `config_class` unless you've done something
    weird.

- `loadcfg( [FILENAME] )`

    This is a bridge to CPAN::Mini::Inject::Config's loadconfig. It sets the
    filename for the configuration, or uses one of the defaults.

- `parsecfg()`

    This is a bridge to CPAN::Mini::Inject::Config's parseconfig.

- `site( [SITE] )`

    Returns the CPAN site that CPAN::Mini::Inject chose from the
    list specified in the `remote` directive.

- `testremote`

    Test each site listed in the remote parameter of the config file by performing
    a get on each site in order for authors/01mailrc.txt.gz. The first site to
    respond successfully is set as the instance variable site.

    ```
    print "$mcpi->{site}\n"; # ftp://ftp.cpan.org/pub/CPAN
    ```

    `testremote` accepts an optional parameter to enable verbose mode.

- `update_mirror`

    This is a subclass of CPAN::Mini.

- `add`

    Add a new module to the repository. The add method copies the module
    file into the repository with the same structure as a CPAN site. For
    example CPAN-Mini-Inject-0.01.tar.gz is copied to
    MYCPAN/authors/id/S/SS/SSORICHE. add creates the required directory
    structure below the repository.

    Packages found in the distribution will be added to the module list
    (for example both `CPAN::Mini::Inject` and `CPAN::Mini::Inject::Config`
    will be added to the `modules/02packages.details.txt.gz` file).

    Packages will be looked for in the `provides` key of the META file if present,
    otherwise the files in the dist will be searched.
    See [Dist::Metadata](https://metacpan.org/pod/Dist::Metadata) for more information.

    - module

        The name of the module to add.
        The distribution file will be searched for modules
        but you can specify the main one explicitly.

    - authorid

        CPAN author id. This does not have to be a real author id.

    - version

        The modules version number.
        Module names and versions will be determined,
        but you can specify one explicitly.

    - file

        The tar.gz of the module.

### Example

```perl
add( module => 'Module::Name',
     authorid => 'AUTHOR',
     version => 0.01,
     file => './Module-Name-0.01.tar.gz' );
```

- `added_modules`

    Returns a list of hash references describing the modules added by this instance.
    Each hashref will contain `file`, `authorid`, and `modules`.
    The `modules` entry is a hashref of module names and versions included in the `file`.

    The list is cumulative.
    There will be one entry for each time ["add"](#add) was called.

    This functionality is mostly provided for the included [mcpani](https://metacpan.org/pod/mcpani) script
    to be able to verbosely print all the modules added.

- `inject`

    Insert modules from the repository into the local CPAN::Mini mirror. inject
    copies each module into the appropriate directory in the CPAN::Mini mirror
    and updates the CHECKSUMS file.

    Passing a value to `inject` enables verbose mode, which lists each module
    as it's injected.

- `updpackages`

    Update the CPAN::Mini mirror's modules/02packages.details.txt.gz with the
    injected module information.

- `updauthors`

    Update the CPAN::Mini mirror's authors/01mailrc.txt.gz with
    stub information should the author not actually exist on CPAN

- `readlist`

    Load the repository's modulelist.

- `writelist`

    Write to the repository modulelist.

# See Also

[CPAN::Mini](https://metacpan.org/pod/CPAN::Mini)

# Current Maintainer

Christian Walde `<walde.christian@googlemail.com>`

# Original Author

Shawn Sorichetti, `<ssoriche@cpan.org>`

# Acknowledgements

Special thanks to David Bartle, for bringing this module up
to date, and resolving the reported bugs.

Thanks to Jozef Kutej <jozef@kutej.net> for numerous patches.

# Bugs

Please report any bugs or feature requests to
`bug-cpan-mini-inject@rt.cpan.org`, or through the web interface at
[http://rt.cpan.org](http://rt.cpan.org).  I will be notified, and then you'll automatically
be notified of progress on your bug as I make changes.

# Copyright & License

Copyright 2008-2009 Shawn Sorichetti, Andy Armstrong, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
