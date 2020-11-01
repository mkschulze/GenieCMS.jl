from werkzeug.datastructures import MultiDict


class ImmutableTypeConversionDict(  # type: ignore
    ImmutableDictMixin, TypeConversionDict
):
    """
    Works like a :class:`TypeConversionDict` but does not support
    modifications.
    .. versionadded:: 0.5
    

    def copy(self) -> TypeConversionDict:
        """
        Return a shallow mutable copy of this object.  Keep in mind that
        the standard library's :func:`copy` function is a no-op for this class
        like for any other python immutable type (eg: :class:`tuple`).
        """
        return TypeConversionDict(self)

    def __copy__(self) -> "ImmutableTypeConversionDict":
        return self


class MultiDict(TypeConversionDict):
    """A :class:`MultiDict` is a dictionary subclass customized to deal with
    multiple values for the same key which is for example used by the parsing
    functions in the wrappers.  This is necessary because some HTML form
    elements pass multiple values for the same key.
    :class:`MultiDict` implements all standard dictionary methods.
    Internally, it saves all values for a key as a list, but the standard dict
    access methods will only return the first value for a key. If you want to
    gain access to the other values, too, you have to use the `list` methods as
    explained below."""

    Basic Usage:
    >>> d = MultiDict([('a', 'b'), ('a', 'c')])
    >>> d
    MultiDict([('a', 'b'), ('a', 'c')])
    >>> d['a']
    'b'
    >>> d.getlist('a')
    ['b', 'c']
    >>> 'a' in d
    True
    """
    It behaves like a normal dict thus all dict functions will only return the
    first value when multiple values for one key are found.
    From Werkzeug 0.3 onwards, the `KeyError` raised by this class is also a
    subclass of the :exc:`~exceptions.BadRequest` HTTP exception and will
    render a page for a ``400 BAD REQUEST`` if caught in a catch-all for HTTP
    exceptions.
    A :class:`MultiDict` can be constructed from an iterable of
    ``(key, value)`` tuples, a dict, a :class:`MultiDict` or from Werkzeug 0.2
    onwards some keyword parameters.
    :param mapping: the initial value for the :class:`MultiDict`.  Either a
                    regular dict, an iterable of ``(key, value)`` tuples
                    or `None`."""
    

    def __init__(self, mapping: Optional[Any] = None) -> None:
        if isinstance(mapping, MultiDict):
            dict.__init__(self, ((k, l[:]) for k, l in mapping.lists()))
        elif isinstance(mapping, dict):
            tmp = {}
            for key, value in mapping.items():
                if isinstance(value, (tuple, list)):
                    if len(value) == 0:
                        continue
                    value = list(value)
                else:
                    value = [value]
                tmp[key] = value
            dict.__init__(self, tmp)
        else:
            tmp = {}  # type: ignore
            for key, value in mapping or ():
                tmp.setdefault(key, []).append(value)
            dict.__init__(self, tmp)

    def __getstate__(self) -> Dict[bytes, Union[List[int], List[bytes]]]:
        return dict(self.lists())  # type: ignore

    def __setstate__(self, value: Dict[Any, Any]) -> None:
        dict.clear(self)
        dict.update(self, value)

    def __getitem__(self, key: Hashable) -> Any:
        """Return the first data value for this key;
        raises KeyError if not found.
        :param key: The key to be looked up.
        :raise KeyError: if the key does not exist.
        """

        if key in self:
            lst = dict.__getitem__(self, key)
            if len(lst) > 0:
                return lst[0]
        raise exceptions.BadRequestKeyError(key)

    def __setitem__(self, key: Hashable, value: Any) -> None:
        """Like :meth:`add` but removes an existing key first.
        :param key: the key for the value.
        :param value: the value to set.
        """
        dict.__setitem__(self, key, [value])

    def add(self, key: Hashable, value: Any) -> None:
        """Adds a new value for the key.
        .. versionadded:: 0.6
        :param key: the key for the value.
        :param value: the value to add.
        """
        dict.setdefault(self, key, []).append(value)

    def getlist(
        self, key: Hashable, type: Optional[Callable[[Any], T]] = None
    ) -> List[Union[Any, T]]:
        """Return the list of items for a given key. If that key is not in the
        `MultiDict`, the return value will be an empty list.  Just like `get`,
        `getlist` accepts a `type` parameter.  All items will be converted
        with the callable defined there.
        :param key: The key to be looked up.
        :param type: A callable that is used to cast the value in the
                     :class:`MultiDict`.  If a :exc:`ValueError` is raised
                     by this callable the value will be removed from the list.
        :return: a :class:`list` of all the values for the key.
        """
        try:
            rv = dict.__getitem__(self, key)
        except KeyError:
            return []
        if type is None:
            return list(rv)
        result = []
        for item in rv:
            try:
                result.append(type(item))
            except ValueError:
                pass
        return result

    def setlist(self, key: Hashable, new_list: List[Any]) -> None:
        """Remove the old values for a key and add new ones.  Note that the list
        you pass the values in will be shallow-copied before it is inserted in
        the dictionary.
        >>> d = MultiDict()
        >>> d.setlist('foo', ['1', '2'])
        >>> d['foo']
        '1'
        >>> d.getlist('foo')
        ['1', '2']
        :param key: The key for which the values are set.
        :param new_list: An iterable with the new values for the key.  Old values
                         are removed first.
        """
        dict.__setitem__(self, key, list(new_list))

    def setdefault(self, key: Hashable, default: Optional[T] = None) -> Union[Any, T]:
        """Returns the value for the key if it is in the dict, otherwise it
        returns `default` and sets that value for `key`.
        :param key: The key to be looked up.
        :param default: The default value to be returned if the key is not
                        in the dict.  If not further specified it's `None`.
        """
        if key not in self:
            self[key] = default
        else:
            default = self[key]
        return default

    def setlistdefault(
        self, key: Hashable, default_list: Optional[List[T]] = None
    ) -> List[T]:
        """Like `setdefault` but sets multiple values.  The list returned
        is not a copy, but the list that is actually used internally.  This
        means that you can put new values into the dict by appending items
        to the list:
        >>> d = MultiDict({"foo": 1})
        >>> d.setlistdefault("foo").extend([2, 3])
        >>> d.getlist("foo")
        [1, 2, 3]
        :param key: The key to be looked up.
        :param default_list: An iterable of default values.  It is either copied
                             (in case it was a list) or converted into a list
                             before returned.
        :return: a :class:`list`
        """
        if key not in self:
            default_list = list(default_list or ())
            dict.__setitem__(self, key, default_list)
        else:
            default_list = dict.__getitem__(self, key)
        return default_list

    def items(  # type: ignore
        self, multi: bool = False
    ) -> Iterator[
        Union[
            Tuple[str, str],
            Tuple[str, int],
            Tuple[bytes, int],
            Tuple[bytes, bytes],
            Tuple[str, "FileStorage"],
        ]
    ]:
        """Return an iterator of ``(key, value)`` pairs.
        :param multi: If set to `True` the iterator returned will have a pair
                      for each value of each key.  Otherwise it will only
                      contain pairs for the first value of each key.
        """
        for key, values in dict.items(self):
            if multi:
                for value in values:
                    yield key, value
            else:
                yield key, values[0]

    def lists(self,) -> Iterator[Tuple[Hashable, List[Any]]]:
        """Return a iterator of ``(key, values)`` pairs, where values is the list
        of all values associated with the key."""
        for key, values in dict.items(self):
            yield key, list(values)

    def values(self) -> Iterator[Any]:  # type: ignore
        """Returns an iterator of the first value on every key's value list."""
        for values in dict.values(self):
            yield values[0]

    def listvalues(self):
        """Return an iterator of all values associated with a key.  Zipping
        :meth:`keys` and this is the same as calling :meth:`lists`:
        >>> d = MultiDict({"foo": [1, 2, 3]})
        >>> zip(d.keys(), d.listvalues()) == d.lists()
        True
        """
        return dict.values(self)

    def copy(self) -> Union["MultiDict", "OrderedMultiDict"]:
        """Return a shallow copy of this object."""
        return self.__class__(self)

    def deepcopy(self, memo: None = None) -> Union["MultiDict", "OrderedMultiDict"]:
        """Return a deep copy of this object."""
        return self.__class__(deepcopy(self.to_dict(flat=False), memo))

    def to_dict(self, flat: bool = True) -> Dict[Hashable, Any]:
        """Return the contents as regular dict.  If `flat` is `True` the
        returned dict will only have the first item present, if `flat` is
        `False` all values will be returned as lists.
        :param flat: If set to `False` the dict returned will have lists
                     with all the values in it.  Otherwise it will only
                     contain the first value for each key.
        :return: a :class:`dict`
        """
        if flat:
            return dict(self.items())
        return dict(self.lists())

    def update(self, other_dict: Mapping) -> None:  # type: ignore
        """update() extends rather than replaces existing key lists:
        >>> a = MultiDict({'x': 1})
        >>> b = MultiDict({'x': 2, 'y': 3})
        >>> a.update(b)
        >>> a
        MultiDict([('y', 3), ('x', 1), ('x', 2)])
        If the value list for a key in ``other_dict`` is empty, no new values
        will be added to the dict and the key will not be created:
        >>> x = {'empty_list': []}
        >>> y = MultiDict()
        >>> y.update(x)
        >>> y
        MultiDict([])
        """
        for key, value in iter_multi_items(other_dict):
            MultiDict.add(self, key, value)

    def pop(  # type: ignore
        self, key: str, default: Union["_Missing", int] = _missing
    ) -> int:
        """Pop the first item for a list on the dict.  Afterwards the
        key is removed from the dict, so additional values are discarded:
        >>> d = MultiDict({"foo": [1, 2, 3]})
        >>> d.pop("foo")
        1
        >>> "foo" in d
        False
        :param key: the key to pop.
        :param default: if provided the value to return if the key was
                        not in the dictionary.
        """
        try:
            lst = dict.pop(self, key)

            if len(lst) == 0:
                raise exceptions.BadRequestKeyError(key)

            return lst[0]
        except KeyError:
            if default is not _missing:
                return default  # type: ignore
            raise exceptions.BadRequestKeyError(key)

    def popitem(self) -> Tuple[Any, Any]:
        """Pop an item from the dict."""
        try:
            item = dict.popitem(self)

            if len(item[1]) == 0:
                raise exceptions.BadRequestKeyError(item)

            return (item[0], item[1][0])
        except KeyError as e:
            raise exceptions.BadRequestKeyError(e.args[0])

    def poplist(self, key: Hashable) -> List[Any]:
        """Pop the list for a key from the dict.  If the key is not in the dict
        an empty list is returned.
        .. versionchanged:: 0.5
           If the key does no longer exist a list is returned instead of
           raising an error.
        """
        return dict.pop(self, key, [])

    def popitemlist(self) -> Tuple[Hashable, List[Any]]:
        """Pop a ``(key, list)`` tuple from the dict."""
        try:
            return dict.popitem(self)
        except KeyError as e:
            raise exceptions.BadRequestKeyError(e.args[0])

    def __copy__(self) -> Union["MultiDict", "OrderedMultiDict"]:
        return self.copy()

    def __deepcopy__(
        self, memo: Dict[Any, Any]
    ) -> Union["MultiDict", "OrderedMultiDict"]:
        return self.deepcopy(memo=memo)  # type: ignore

    def __repr__(self) -> str:
        return f"{type(self).__name__}({list(self.items(multi=True))!r})"
