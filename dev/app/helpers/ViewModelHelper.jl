module ViewModelBaseController
  # Build something great

import Users.User

 struct ViewModelBase
      request::String
      user::String
      user_set::Bool
      request_dict::String
      error::String
      user_id::Int 

 end 

function to_dict()

end

end

```
from typing import Optional
you can have Some{T}, Union{T, Nothing} or Union{T, Missing}
depending on what you want to express
https://docs.julialang.org/en/v1/manual/faq/#Nothingness-and-missing-values-1
```




class ViewModelBase:
    def __init__(self):
        self.request: Request = flask.request
        self.__user: Optional[User] = None
        self.__user_set: bool = False
        self.request_dict = request_dict.create('')

        self.error: Optional[str] = None
        self.user_id: Optional[int] = cookie_auth.get_user_id_via_auth_cookie(self.request)

    def to_dict(self):
        data = dict(self.__dict__)
        data['user'] = self.user

        return data

    @property
    def user(self) -> Optional[User]:
        if self.__user or self.__user_set:
            return self.__user

        self.__user_set = True

        if not self.user_id:
            return None

        self.__user = user_service.find_user_by_id(self.user_id)
        return self.__user
