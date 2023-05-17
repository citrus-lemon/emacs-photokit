#include "emacs-module.h"
#import <Photos/Photos.h>
#include <string.h>

int plugin_is_GPL_compatible;

#define Qnil env->intern(env, "nil")
#define DEFUN(name, func, min_arity, max_arity, docstring)                     \
  {                                                                            \
    emacs_value Qsym = env->intern(env, name);                                 \
    emacs_value Sfun =                                                         \
        env->make_function(env, min_arity, max_arity, func, docstring, nil);   \
    emacs_value args[] = {Qsym, Sfun};                                         \
    env->funcall(env, env->intern(env, "fset"), 2, args);                      \
  }
#define PROVIDE(feat)                                                          \
  {                                                                            \
    emacs_value Qfeat = env->intern(env, feat);                                \
    emacs_value Qprovide = env->intern(env, "provide");                        \
    emacs_value args[] = {Qfeat};                                              \
    env->funcall(env, Qprovide, 1, args);                                      \
  }

static emacs_value cloudIdentifierToLocalIdentifer(emacs_env *env,
                                                   ptrdiff_t nargs,
                                                   emacs_value args[],
                                                   void *data) EMACS_NOEXCEPT {
  emacs_value str = args[0];
  emacs_value result = Qnil;
  if (!env->is_not_nil(env,
                       env->funcall(env, env->intern(env, "stringp"), 1, &str)))
    return result;
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  NSString *value;
  {
    char *buffer = NULL;
    ptrdiff_t buffer_size = 0;
    env->copy_string_contents(env, str, buffer, &buffer_size);
    buffer = (char *)malloc(buffer_size);
    env->copy_string_contents(env, str, buffer, &buffer_size);
    value = [NSString stringWithUTF8String:buffer];
    free(buffer);
  }
  PHCloudIdentifier *cloud_identifier =
      [[PHCloudIdentifier alloc] initWithStringValue:value];
  NSArray<PHCloudIdentifier *> *identifiers = @[ cloud_identifier ];

  NSDictionary<PHCloudIdentifier *, PHLocalIdentifierMapping *> *dic =
      [[PHPhotoLibrary sharedPhotoLibrary]
          localIdentifierMappingsForCloudIdentifiers:identifiers];

  PHLocalIdentifierMapping *local_id_map;

  if (!dic)
    goto end;

  local_id_map = dic[cloud_identifier];

  if (!local_id_map)
    goto end;

  if ([local_id_map error]) {
    NSString *error = [[local_id_map error] localizedDescription];
    emacs_value Serr =
        env->make_string(env, [error UTF8String], strlen([error UTF8String]));
    env->funcall(env, env->intern(env, "error"), 1, &Serr);
    goto end;
  }

  {
    NSString *local_id_str = [local_id_map localIdentifier];
    result = env->make_string(env, [local_id_str UTF8String],
                              strlen([local_id_str UTF8String]));
  }

end:
  [pool release];
  return result;
}

static emacs_value localIdentiferToCloudIdentifier(emacs_env *env,
                                                   ptrdiff_t nargs,
                                                   emacs_value args[],
                                                   void *data) EMACS_NOEXCEPT {
  emacs_value str = args[0];
  emacs_value result = Qnil;
  if (!env->is_not_nil(env,
                       env->funcall(env, env->intern(env, "stringp"), 1, &str)))
    return result;
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  NSString *value;
  {
    char *buffer = NULL;
    ptrdiff_t buffer_size = 0;
    env->copy_string_contents(env, str, buffer, &buffer_size);
    buffer = (char *)malloc(buffer_size);
    env->copy_string_contents(env, str, buffer, &buffer_size);
    value = [NSString stringWithUTF8String:buffer];
    free(buffer);
  }
  NSArray<NSString *> *identifiers = @[ value ];

  NSDictionary<NSString *, PHCloudIdentifierMapping *> *dic =
      [[PHPhotoLibrary sharedPhotoLibrary]
          cloudIdentifierMappingsForLocalIdentifiers:identifiers];

  PHCloudIdentifierMapping *cloud_id_map;

  if (!dic)
    goto end;

  cloud_id_map = dic[value];

  if (!cloud_id_map)
    goto end;

  if ([cloud_id_map error]) {
    NSString *error = [[cloud_id_map error] localizedDescription];
    emacs_value Serr =
        env->make_string(env, [error UTF8String], strlen([error UTF8String]));
    env->funcall(env, env->intern(env, "error"), 1, &Serr);
    goto end;
  }

  {
    NSString *cloud_id_str = [[cloud_id_map cloudIdentifier] stringValue];
    result = env->make_string(env, [cloud_id_str UTF8String],
                              strlen([cloud_id_str UTF8String]));
  }

end:
  [pool release];
  return result;
}

int emacs_module_init(struct emacs_runtime *runtime) EMACS_NOEXCEPT {
  if (runtime->size < sizeof(*runtime))
    return 1;
  emacs_env *env = runtime->get_environment(runtime);
  DEFUN("photokit--ns-cloud-id-to-local-id", cloudIdentifierToLocalIdentifer, 1,
        1, "localIdentifierMappingsForCloudIdentifiers of sharedPhotoLibrary");
  DEFUN("photokit--ns-local-id-to-cloud-id", localIdentiferToCloudIdentifier, 1,
        1, "cloudIdentifierMappingsForLocalIdentifiers of sharedPhotoLibrary");
  PROVIDE("photokit-nsphotolibrary");
  return 0;
}
