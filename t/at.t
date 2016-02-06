
{
  package MyApp::Controller::User::Records;
  $INC{'MyApp/Controller/User/Records.pm'} = __FILE__;

  use Moose;
  use MooseX::MethodAttributes;
  use Types::Standard qw/Int Str/;

  extends 'Catalyst::Controller';
  with 'Catalyst::ControllerRole::At';

  # http://localhost/global/$arg/$arg 
  sub global :At(/global/{}/{}) {
    my ($self, $c, $arg1, $arg2) = @_;
  }

  sub int :At(/int/{:Int}) {
    my ($self, $c, $arg1, $arg2) = @_;
  }

  sub int2 :At(/int/{:Int}/{str:Str}) {
    my ($self, $c, $arg1, $arg2) = @_;
    $_->res->body($_{str});
  }

  __PACKAGE__->meta->make_immutable;

  package MyApp;
  use Catalyst;

  MyApp->setup;
}

use Test::Most;
use HTTP::Request::Common;
use Catalyst::Test 'MyApp';

{
  ok my $res = request GET "/global/1/2";
  is $res->code, 200;
}

{
  ok my $res = request GET "/int/100";
  is $res->code, 200;
}
  
{
  ok my $res = request GET "/int/xxx";
  is $res->code, 500;
}

{
  ok my $res = request GET "/int/100/333";
  is $res->code, 200;
  is $res->content, '333';
}
  
{
  ok my $res = request GET "/int/xxx/xxxs";
  is $res->code, 500;
}

done_testing;

__END__

  # http://localhost/user/list?q=$string
  sub list :At($action?{q:Str}) {
    my ($self, $c) = @_;
  }       

  # http://localhost/user/$integer
  sub find :At($controller/{id:Int}) {
    my ($self, $c, $int) = @_;
  }  


PathPart and PathPart() are the same
No given PathPart is the same as saying PathPart (or PathPart()).
All three mean 'pathpart is the action name'.   Keep in mind its
just the action name, not the controller namespace + name (not like Local)

But PathPart('') means 'no part part'.
h
*PathPrefix is path of Controller Prefix, which is derived from namespace...*
PathPrefix ignores the action name totally

Chained(/) starts a chain.  All Chains start from the root of the domain.  

Chained(/ddd) is under /ddd (absolute path)
Chained(ddd) is under something called ddd in the current controller
Chained(../ddd) is 'one level up' to ddd
ChainedParent is a special like Chained(.../$actionname)

!!!!!1
At($controller/foo) => Chained(/) PathPart($controller/foo) Args(0) { ... }
At($controller/foo/{*}) => Chained(/) PathPart($controller/foo) Args { ... }
At($controller/foo/{}) => Chained(/) PathPart($controller/foo) Args(1) { ... }
At($controller/foo/{:Int}) => Chained(/) PathPart($controller/foo) Args(Int) { ... }
At($controller/foo/{id:Int}) => 
  Chained(/) PathPart($controller/foo) Args(Int) Does(NamedFields) Field(id=>$args[0]) { ... }


At($controller/foo/...) => Chained(/) PathPart($controller/foo) CaptureArgs(0) { ... }
At($controller/foo/{}/...) => Chained(/) PathPart($controller/foo) CaptureArgs(1) { ... }
At($controller/foo/{:Int}/...) => Chained(/) PathPart($controller/foo) CaptureArgs(Int) { ... }
At($controller/foo/{id:Int}/...) => Chained(/) PathPart($controller/foo) CaptureArgs(Int) { ... }


At(./{id:Int}?{page:Int}%{name:Str}{age:Int}) 
At(./{id:Int}%{:UserForm}*) ????

  Via(..) => Chained(..) PathPart('') Args(0) { ... } ?????

  # /root/*
  sub root :Chained(/) PathPart('root') CaptureArgs(1) {

  }
     /root/*  +      =>  /root/*/*
    sub myaction :Chained(root) PathParts('') Args(0) {
    }


  sub root :At(root/...) { ... }
  sub root :At($controller/root/...) { ... }
  sub root :At($controller/root/$next) { ... } 

    sub under :Via(root) At({}) { ... }


At(:namespace/...)
At(:ns/:actionname/...
At(:local/...) sub myaction :Chained(/) PathPart($controller/myaction) CaptureArgs(0) { ... }
At(:local/{id:Int}/...) sub myaction :Chained(/) PathPart($controller/myaction) CaptureArgs(0) { ... }


At(:local/{$*})  sub myaction :Local Args { ... }

At(:controller/:action/{id:Int})
At(./:action/{id:Int})

At(./:action/{}/)

Under(root) At(a/b/c/{id}/...)
Under(root) At($action/{id}/{date}
/)


sub myaction($view, $model) :At($local/{id}) {
  $view->ok($model->find($id));
}

  NamedFields(id=>$args[0])
  
sub myaction :At($local/{id:Int}?{page}{order:Int}) {
  $_->view->ok($_->model->find($_{id})
    || $_->detach('/not_found'));
}

  sub notfound :At($local/{id:Int}?{page}&{order:Int}) {
    $_->view->not_found(message => "Id $_{id} is not in the database");
  }

  sub myaction :At($local/{u:User}?{page}&{order:Int}) {
    $_->view->ok($_{u});
  }

sub myaction($view, $model M::Schema::User::Result) :At($local/{id}) {
  $view->ok($model->find($id));
}


Via(action)
Via(/path/to)
Via(../to)
Via(../:action)
Via(:up/:action)


At(:action/{id:Int}?{sort='desc':SortEnum})


Take what is inside Via, expand placeholders, and set Chained($val);
Take what is inside At
  - if Via doesn't exist, do Chained(/)
  - figure out any pathparts (after expanding placeholders
  - figure out any Args(X), Args or CaptureArgs(x) (including Constraints).
  - Add actionroles for  Named Args as need,

An At has a path part section an args or capture args section (look for trailing ...)
  and a query section.

package MyApp::Controller::Example;

use Moose;
use MooseX::MethodAttributes;

extends 'Catalyst::Controller';

sub root :At($controller/...) { }

  sub endpoint :Via(root) At({id}) {
    my ($self, $c, $id) = @_;
  }

  sub endpoin2 :Under(root) At({id}/{@}) {
    my ($self, $c, @args) = @_;
  }

__PACKAGE__->meta->make_immutable;

package MyApp::Controller::Example;

use Moose;
use MooseX::MethodAttributes;

extends 'Catalyst::Controller';

sub root Chained(/) PathPrefix CaptureArgs(0) { }

  sub endpoint :Chained(root) PathPrefix('') Args(1) {
    my ($self, $c, $id) = @_;
  }

  sub endpoin2 :Chained(root) PathPrefix('') Args {
    my ($self, $c, @args) = @_;
  }

__PACKAGE__->meta->make_immutable;


__END__

?? What URL paths are mapped here
?? what does 'warn $_{id}' do?
?? Would :Via work as well as :Under?


At(/foo/{$:User.0}/{$:User.1}%{$:User.age}{$:User.name}
At(/user/{id:User}%{params*:User}

If a Type::Foo accepts context, then $c is part of any coercions

sub myaction(User $u) :At(/user/{id:User}) {

}


sub foo :Local Named(foo=>$arg[0],bar=>$query{id}) 


sub foo :At(./{id:User}) { ... }
sub foo :At(./{id:User,User.email}) { ... }
sub foo :At(./{id:User,User.email}) { ... }


sub user :At(./{id:User} { }
  sub friend :Via(user) At({id:Friend[user:User.id


#######

sub myaction([$id1,$id2]->User $u) At(users/{id1:Int}/{id2:Int})
sub myaction([Arg,Arg]->User $u) At(users/{id1:Int}/{id2:Int})

# User isa Model::Type::User

sub myaction(User $u) Via(root) At(users/{User.0:id1}/{User.1:id2})
{
  $_{User} isa Model::Schema::User::Result
}

OR

sub myaction([id1,id2]->User $u ==> UserResultSet) 
    Via(root) At(users/{id1:Int}/{id2:Int})
{
  $_{User} isa Model::Schema::User::Result
}

is User->coerce([id1,id2])

Model::Types::User

sub ACCEPT_CONTENT {

  my $UserRS = $c->model->isa('UserRS') 
    ? $c->model : $c->model(Schema::User)

  User isa Ref Model::User::Result
  coerce from [Int,Int]
  via $c->model(User)->find($_[0],$_[1])


######

__PACKAGE__->register_actions(
  Path {
    'foo',
    Action {
      my ($self, $c) = @;
    },
  }


);

action user(Int->User $u => User) At($local/{id:Int}) {
  return $u;
}

  return $ctx->created($u)
