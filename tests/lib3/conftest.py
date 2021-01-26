import os
import pytest

from test_appliance import find_test_functions, find_test_filenames, DATA

import test_yaml

collect_ignore_glob = ['*.py']

class PyYAMLItem(pytest.Item):
    def __init__(self, parent=None, config=None, session=None, nodeid=None, function=None, filenames=None, **kwargs):
        self._function = function
        self._fargs = filenames
        self._fkwargs = kwargs

        super().__init__(self._testname, parent, config, session, nodeid)
        self.fspath = function.__code__.co_filename
    @property
    def _testname(self):
        if self._fargs:
            return f'{self._function.__name__}_{self._fargs[0]}'
        else:
            return self._function.__name__
    def runtest(self):
        self._function(verbose=False, *self._fargs, **self._fkwargs)


def pytest_collection_modifyitems(session, config, items):
    test_functions = find_test_functions(test_yaml)
    test_filenames = find_test_filenames(DATA)
    for function in test_functions:
        include_functions = None
        include_filenames = None
        # if include_functions and function.__name__ not in include_functions:
        #     continue
        if function.unittest:
            for base, exts in test_filenames:
                if include_filenames and base not in include_filenames:
                    continue
                filenames = []
                for ext in function.unittest:
                    if ext not in exts:
                        break
                    filenames.append(os.path.join(DATA, base + ext))
                else:
                    skip_exts = getattr(function, 'skip', [])
                    for skip_ext in skip_exts:
                        if skip_ext in exts:
                            break
                    else:
                        items.append(PyYAMLItem.from_parent(parent=session, function=function, filenames=filenames))
        else:
            items.append(PyYAMLItem.from_parent(parent=session, function=function, filenames=filenames))
