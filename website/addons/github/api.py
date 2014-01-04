"""

"""

import os
import json
import uuid
import base64
import urllib
import datetime
import requests

from hurry.filesize import size, alternative

from website import settings

from . import settings as github_settings

GH_URL = 'https://github.com/'
API_URL = 'https://api.github.com/'
OAUTH_AUTHORIZE_URL = 'https://github.com/login/oauth/authorize'
OAUTH_ACCESS_TOKEN_URL = 'https://github.com/login/oauth/access_token'

SCOPE = ['repo']

github_cache = {}

def oauth_start_url(node, state=None):
    """

    """
    state = state or str(uuid.uuid4())

    redirect_uri = os.path.join(
        settings.DOMAIN, 'api', 'v1', 'addons', 'github', 'callback', node._id
    )
    query_string = urllib.urlencode({
        'client_id': github_settings.CLIENT_ID,
        'redirect_uri': redirect_uri,
        'scope': ','.join(SCOPE),
        'state': state,
    })
    url = '{0}/?{1}'.format(
        OAUTH_AUTHORIZE_URL,
        query_string
    )

    return state, url


def oauth_get_token(code):
    """

    """
    return requests.get(
        OAUTH_ACCESS_TOKEN_URL,
        data={
            'client_id': github_settings.CLIENT_ID,
            'client_secret': github_settings.CLIENT_SECRET,
            'code': code,
        }
    )


class GitHub(object):

    def __init__(self, user=None, token=None, key=None):
        self.user = user
        self.token = token
        self.key = key

    @classmethod
    def from_settings(cls, settings):
        return cls(
            None, None,
            key=settings.oauth_access_token,
        )

    def _send(self, url, method='get', output='json', cache=True, **kwargs):
        """

        """
        func = getattr(requests, method.lower())

        # Add access token to params
        params = kwargs.pop('params', {})
        if self.key is not None and 'access_token' not in params:
            params['access_token'] = self.key

        # Build auth
        auth = kwargs.pop('auth', None)
        if 'access_token' not in params:
            if auth is None and self.user is not None and self.token is not None:
                auth = (self.user, self.token)
        else:
            auth = None

        # Add if-modified-since header if needed
        headers = kwargs.pop('headers', {})
        cache_key = '{0}::{1}'.format(url, method)
        cache_data = github_cache.get(cache_key)
        if cache and cache_data:
            if 'if-modified-since' not in headers:
                headers['if-modified-since'] = cache_data['date'].strftime('%c')

        # Send request
        req = func(url, params=params, auth=auth, headers=headers, **kwargs)

        # Pull from cache if not modified
        if cache and cache_data and req.status_code == 304:
            return cache_data['data']

        # Get return value
        rv = None
        if 200 <= req.status_code < 300:
            if output is None:
                rv = req
            else:
                rv = getattr(req, output)
                if callable(rv):
                    rv = rv()

        # Cache return value if needed
        if cache and rv:
            if req.headers.get('last-modified'):
                github_cache[cache_key] = {
                    'data': rv,
                    'date': datetime.datetime.utcnow(),
                }

        return rv

    def repo(self, user, repo):

        return self._send(
            os.path.join(API_URL, 'repos', user, repo)
        )

    def branches(self, user, repo, branch=None):

        url = os.path.join(API_URL, 'repos', user, repo, 'branches')
        if branch:
            url = os.path.join(url, branch)

        return self._send(url)

    def commits(self, user, repo, path=None):
        """Get commits for a repo or file.

        :param str user: GitHub user name
        :param str repo: GitHub repo name
        :param str path: Path to file within repo
        :return list: List of commit dicts from GitHub; see
            http://developer.github.com/v3/repos/commits/

        """
        return self._send(
            os.path.join(
                API_URL, 'repos', user, repo, 'commits'
            ),
            params={
                'path': path,
            }
        )

    def history(self, user, repo, path):
        """Get commit history for a file.

        :param str user: GitHub user name
        :param str repo: GitHub repo name
        :param str path: Path to file within repo
        :return list: List of dicts summarizing commits

        """
        req = self.commits(user, repo, path)

        if req:
            return [
                {
                    'sha': commit['sha'],
                    'name': commit['author']['name'],
                    'email': commit['author']['email'],
                    'date': commit['author']['date'],
                }
                for commit in req
            ]

    def tree(self, user, repo, branch=None, recursive=True, registration_data=None):
        """Get file tree for a repo.

        :param str user: GitHub user name
        :param str repo: GitHub repo name
        :param str branch: Branch name
        :param bool recursive: Walk repo recursively
        :param dict registration_data: Registered commit data
        :return tuple: Tuple of commit ID and tree JSON; see
            http://developer.github.com/v3/git/trees/

        """
        if branch:
            commit_id = branch
        else:
            _repo = self.repo(user, repo)
            if _repo is None:
                return None, None
            commit_id = _repo['default_branch']

        if registration_data is not None:
            for registered_branch in registration_data:
                if commit_id == registered_branch['name']:
                    commit_id = registered_branch['commit']['sha']
                    break

        req = self._send(os.path.join(
                API_URL, 'repos', user, repo, 'git', 'trees', commit_id
            ),
            params={
                'recursive': int(recursive)
            },
        )

        if req is not None:
            return commit_id, req
        return commit_id, None

    def file(self, user, repo, path, ref=None):

        params = {
            'ref': ref,
        }

        req = self._send(
            os.path.join(
                API_URL, 'repos', user, repo, 'contents', path
            ),
            cache=False,
            params=params,
        )

        if req:
            content = req['content']
            return req['name'], base64.b64decode(content)

        return None, None

    def starball(self, user, repo, archive='tar'):

        req = self._send(
            os.path.join(
                API_URL, 'repos', user, repo, archive + 'ball'
            ),
            cache=False,
            output=None,
        )

        if req.status_code == 200:
            return dict(req.headers), req.content
        return None, None

    def set_privacy(self, user, repo, private):
        """Set privacy of GitHub repo.

        :param str user: GitHub user name
        :param str repo: GitHub repo name
        :param bool private: Make repo private; see
            http://developer.github.com/v3/repos/#edit

        """
        req = self._send(
            os.path.join(
                API_URL, 'repos', user, repo
            ),
            method='patch',
            cache=False,
            data=json.dumps({
                'name': repo,
                'private': private,
            })
        )

        return req

    ########
    # CRUD #
    ########

    def upload_file(self, user, repo, path, message, content, sha=None, branch=None, committer=None, author=None):

        data = {
            'message': message,
            'content': base64.b64encode(content),
            'sha': sha,
            'branch': branch,
            'committer': committer,
            'author': author,
        }

        return self._send(
            os.path.join(
                API_URL, 'repos', user, repo, 'contents', path
            ),
            method='put',
            cache=False,
            data=json.dumps(data),
        )

    def delete_file(self, user, repo, path, message, sha, branch=None, committer=None, author=None):

        data = {
            'message': message,
            'sha': sha,
            'branch': branch,
            'committer': committer,
            'author': author,
        }

        return self._send(
            os.path.join(
                API_URL, 'repos', user, repo, 'contents', path
            ),
            method='delete',
            cache=False,
            data=json.dumps(data),
        )

#

type_map = {
    'tree': 'folder',
    'blob': 'file',
}

def tree_to_hgrid(tree, user, repo, node, ref=None, hotlink=True):
    """Convert GitHub tree data to HGrid format.

    :param list tree: JSON description of git tree
    :param str user: GitHub user name
    :param str repo: GitHub repo name
    :param Node node: OSF Node
    :param str ref: Branch or SHA
    :param bool hotlink: Hotlink files if ref provided; will yield broken
        links if repo is private

    """
    grid = []

    parent = {
        'uid': 'tree:__repo__',
        'name': 'GitHub :: {0}'.format(repo),
        'parent_uid': 'null',
        'url': '',
        'type': 'folder',
        'uploadUrl': node.api_url + 'github/file/'
    }

    grid.append(parent)

    for item in tree:

        split = os.path.split(item['path'])

        row = {
            'uid': item['type'] + ':' + '||'.join(['__repo__', item['path']]),
            'name': split[1],
            'parent_uid': 'tree:' + '||'.join(['__repo__', split[0]]).strip('||'),
            'type': type_map[item['type']],
            'uploadUrl': node.api_url + 'github/file/',
        }
        if ref is not None:
             row['uploadUrl'] += '?ref=' + ref

        if item['type'] == 'blob':
            row['sha'] = item['sha']
            row['url'] = item['url']
            row['size'] = [
                item['size'],
                size(item['size'], system=alternative)
            ]
            if hotlink and ref:
                row['download'] = os.path.join(
                    GH_URL, user, repo, 'blob', ref, item['path']
                ) + '?raw=true'
            else:
                row['download'] = node.api_url + 'github/file/{0}'.format(item['path'])
                if ref is not None:
                    row['download'] += '/?ref=' + ref
                    row['ref'] = ref
        else:
            row['uploadUrl'] = node.api_url + 'github/file/{0}/'.format(item['path'])
            if ref is not None:
                 row['uploadUrl'] += '?ref=' + ref

        grid.append(row)

    return grid
