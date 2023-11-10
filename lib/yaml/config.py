from __future__ import annotations

import inspect
import typing as t

if t.TYPE_CHECKING and not hasattr(t, 'override'):
    from typing_extensions import override
    t.override = override

from functools import lru_cache, partialmethod
from .tagset import TagSet


class _YamlConfigurable(t.Protocol):
    _actual_sig: t.ClassVar[t.Callable[..., t.Any] | None]
    _stored_config: t.ClassVar[dict[str, t.Any] | None] = {}

    @classmethod
    def config(cls, *args, **kwargs) -> t.Any: ...

    @classmethod
    def _config_impl(cls, **kwargs) -> t.Any: ...

    def __init_subclass__(cls, **kwargs):
        if cls.config.__name__ != '_config_impl':
            cls._actual_sig = cls.config

        cls.config = cls._config_impl


class _LoaderProtocol(t.Protocol):
    @classmethod
    def load(cls, stream, loader: _LoaderProtocol | None = None, **kwargs) -> t.Any:
        import yaml
        return yaml._old_load(stream, Loader=loader or cls)


def _type_factory(base_type: type[T], **kwargs) -> type[T]:
    return type(f'Customized_{base_type.__name__}', (base_type,), {})


class LoaderConfigMixin(_YamlConfigurable, _LoaderProtocol):
    @classmethod
    # FIXME: @t.override
    #@lru_cache  # FIXME: feels wrong, probably an issue
    def _config_impl(cls, **kwargs) -> t.Any:
        sig = inspect.signature(cls._actual_sig)
        ba = sig.bind(**kwargs)

        new_type = _type_factory(cls)

        # FIXME: until all the builtins bootstrap this way, figure out a sane default for origin classes and user classes?
        # FIXME: merge existing config;
        new_type._stored_config = ba.kwargs

        # FIXME: add support for arbitrary kwargs passthru ala dumper?

        tagset = ba.kwargs.get('tagset', ...)

        if tagset is not ...:
            # FIXME: provide a base class hook/method for this reset
            new_type.yaml_implicit_resolvers = {}
            new_type.init_resolvers(tagset.resolvers)
            new_type.yaml_constructors = {}
            new_type.init_constructors(tagset.constructors)

        return new_type


class CommonLoaderConfig(LoaderConfigMixin):
    @classmethod
    def config(cls: _LoaderProtocol, *, tagset: TagSet | ... = ...) -> _LoaderProtocol: ...


class _DumperProtocol(t.Protocol):
    @classmethod
    def dump(cls, data, stream=None, dumper: _DumperProtocol | None = None, **kwargs) -> t.Any:
        import yaml
        return yaml._old_dump(data, stream, Dumper=dumper or cls, **kwargs)


class DumperConfigMixin(_YamlConfigurable, _DumperProtocol):  # FIXME: move the args opt-in to the mixin graft sites
    @classmethod
    # FIXME: @t.override
    def _config_impl(cls, **kwargs) -> t.Any:
        sig = inspect.signature(cls._actual_sig)
        ba = sig.bind(**kwargs)

        # FIXME: merge existing config;
        patched_init = partialmethod(cls.__init__, **ba.kwargs)

        new_type = _type_factory(cls)

        # FIXME: pass via dict in type constructor, or ? (dict breaks lru_cache on type_factory)
        new_type.__init__ = patched_init

        # FIXME: until all the builtins bootstrap this way, figure out a sane default for origin classes and user classes?
        # FIXME: merge existing config;
        new_type._stored_config = ba.kwargs

        # FIXME: add support for arbitrary kwargs passthru ala dumper?

        tagset = ba.kwargs.get('tagset', ...)

        # FIXME: support all the dynamic dispatch types (multi*, etc)
        if tagset is not ...:
            # FIXME: provide a base class hook/method for this reset
            new_type.yaml_implicit_resolvers = {}
            new_type.init_resolvers(tagset.resolvers)
            new_type.yaml_representers = {}
            new_type.init_representers(tagset.representers)

        return new_type


class CommonDumperConfig(DumperConfigMixin):
    @classmethod
    def config(cls: _DumperProtocol, *,
               tagset: TagSet | ... = ...,
               default_style: str | None | ... = ...,
               default_flow_style: str | None | ... = ...,
               canonical: bool | None | ... = ...,
               indent: int | None | ... = ...,
               width: int | None | ... = ...,
               allow_unicode: bool | None | ... = ...,
               line_break: bool | None | ... = ...,
               encoding: str | None | ... = ...,
               version: str | None | ... = ...,
               tags: list[str] | None | ... = ...,
               explicit_start: bool | None | ... = ...,
               explicit_end: bool | None | ... = ...,
               sort_keys: bool | None | ... = ..., ) -> _DumperProtocol: ...
