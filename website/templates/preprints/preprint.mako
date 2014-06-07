<%inherit file="base.mako"/>

<%def name="content()">

    <%
        import json
        is_project = node['category'] == 'project'
    %>
    % if node['is_registration']:
        <div class="alert alert-info">This ${node['category']} is a registration of <a class="alert-link" href="${node['registered_from_url']}">this ${node["category"]}</a>; the content of the ${node["category"]} has been frozen and cannot be edited.
        </div>
        <style type="text/css">
            .watermarked {
                background-image:url('/static/img/read-only.png');
                background-repeat:repeat;
            }
        </style>
    % endif

    % if node['link'] and not node['is_public'] and not user['can_edit']:
        <div class="alert alert-info">This ${node['category']} is being viewed through the private link generated by this project contributor; the content of the ${node["category"]} cannot be edited and you are responsible to keep the private link safe.
        </div>
    % endif

    <div id="projectScope">
        <header class="subhead" id="overview">
            <div class="row">

                <div class="col-md-7 cite-container">
                    <h1 class="node-title">
                        <span id="nodeTitleEditable">${node['title']}</span>
                    </h1>
                </div><!-- end col-md-->

                <div class="col-md-5">
                    <div class="btn-toolbar node-control pull-right">
                        <div class="btn-group">
                            %if not node["is_public"]:
                                <button class='btn btn-default disabled'>Private</button>
                            % if 'admin' in user['permissions']:
                                <a class="btn btn-default" data-bind="click: makePublic">Make Public</a>
                            % endif
                            %else:
                            % if 'admin' in user['permissions']:
                                <a class="btn btn-default" data-bind="click: makePrivate">Make Private</a>
                            % endif
                                <button class="btn btn-default disabled">Public</button>
                            %endif
                        </div><!-- end btn-group -->

                        <div class="btn-group">

                            <a
                                % if user_name and (node['is_public'] or user['is_contributor']) and not node['is_registration']:
                                    data-bind="click: toggleWatch, tooltip: {title: watchButtonAction, placement: 'bottom'}"
                                    class="btn btn-default"
                                % else:
                                    class="btn btn-default disabled"
                                % endif
                                    href="#">
                                <i class="icon-eye-open"></i>
                                <span data-bind="text: watchButtonDisplay" id="watchCount"></span>
                            </a>

                            <a rel="tooltip" title="Duplicate"
                               class="btn btn-default${ '' if is_project else ' disabled'}" href="#"
                               data-toggle="modal" data-target="#duplicateModal">
                                <span class="glyphicon glyphicon-share"></span>&nbsp; ${ node['templated_count'] + node['fork_count'] + node['points'] }
                            </a>

                        </div><!-- end btn-grp -->
                        %if 'badges' in addons_enabled and badges and badges['can_award']:
                            <div class="btn-group">
                                <button class="btn btn-success" id="awardBadge" style="border-bottom-right-radius: 4px;border-top-right-radius: 4px;">
                                    <i class="icon-plus"></i> Award
                                </button>
                            </div><!-- end btn-grp -->
                        %endif
                    </div><!-- end btn-toolbar -->

                </div><!-- end col-md-->

            </div><!-- end row -->


            <p id="contributors">Contributors:
            <span id="contributorsview"><div mod-meta='{
                    "tpl": "util/render_contributors.mako",
                    "uri": "${node["api_url"]}get_contributors/",
                    "replace": true
                }'></div></span>
                % if node['is_fork']:
                    <br />Forked from <a class="node-forked-from" href="/${node['forked_from_id']}/">${node['forked_from_display_absolute_url']}</a> on
                    <span data-bind="text: dateForked.local, tooltip: {title: dateForked.utc}"></span>
                % endif
                % if node['is_registration'] and node['registered_meta']:
                    <br />Registration Supplement:
                % for meta in node['registered_meta']:
                    <a href="${node['url']}register/${meta['name_no_ext']}">${meta['name_clean']}</a>
                % endfor
                % endif
                <br />Date Created:
                <span data-bind="text: dateCreated.local, tooltip: {title: dateCreated.utc}"
                      class="date node-date-created"></span>
                | Last Updated:
            <span data-bind="text: dateModified.local, tooltip: {title: dateModified.utc}"
                  class="date node-last-modified-date"></span>
                ##                % if parent_node['id']:
                ##                    <br />Category: <span class="node-category">${node['category']}</span>
            ##                % elif node['description'] or 'write' in user['permissions']:
            ##                    <br />Description: <span id="nodeDescriptionEditable" class="node-description">${node['description']}</span>
            ##                % endif
                        </p>

            ##            <nav id="projectSubnav" class="navbar navbar-default ">
            ##                <a class="navbar-brand collapse visible-xs">
        ##                    ${'Project' if node['category'] == 'project' else 'Component'} Navigation
        ##                </a>
        ##                <button type="button" class="navbar-toggle collapsed" data-toggle="collapse" data-target=".project-nav">
        ##                    <span class="sr-only">Toggle navigation</span>
        ##                    <span class="icon-bar"></span>
        ##                    <span class="icon-bar"></span>
        ##                    <span class="icon-bar"></span>
        ##                </button>
        ##                <div class="container-fluid">
        ##                    <div class="row">
        ##                        <ul class="nav navbar-nav project-nav collapse navbar-collapse">
        ##                            <li><a href="${node['url']}">Dashboard</a></li>
        ##
        ##                            <li><a href="${node['url']}files/">Files</a></li>
        ##                            <!-- Add-on tabs -->
        ##                            % for addon in addons_enabled:
        ##                                % if addons[addon]['has_page']:
        ##                                    <li>
        ##                                        <a href="${node['url']}${addons[addon]['short_name']}">
        ##                                            % if addons[addon]['icon']:
        ##                                                <img src="${addons[addon]['icon']}" class="addon-logo"/>
        ##                                            % endif
        ##                                            ${addons[addon]['full_name']}
        ##                                        </a>
        ##                                    </li>
        ##                                % endif
        ##                            % endfor
        ##                            % if node['is_public'] or user['is_contributor']:
        ##                                <li><a href="${node['url']}statistics/">Statistics</a></li>
        ##                            % endif
        ##                            % if not node['is_registration']:
        ##                                <li><a href="${node['url']}registrations/">Registrations</a></li>
        ##                            % endif
        ##                            <li><a href="${node['url']}forks/">Forks</a></li>
        ##                            % if user['is_contributor']:
        ##                                <li><a href="${node['url']}contributors/">Contributors</a></li>
        ##                            %endif
        ##                            % if 'write' in user['permissions']:
        ##                                <li><a href="${node['url']}settings/">Settings</a></li>
        ##                            % endif
        ##                        </ul>
        ##                    </div><!-- end row -->
        ##                </div><!-- end container-fluid -->
        ##
        ##            </nav>
                </header>
    </div><!-- end projectScope -->

    % if user['can_comment'] or node['has_comments']:
        <%include file="include/comment_template.mako" />
    % endif

    <%include file="project/modal_generate_private_link.mako"/>
    <%include file="project/modal_add_contributor.mako"/>
    <%include file="project/modal_add_pointer.mako"/>
    <%include file="project/modal_show_links.mako"/>


    <div class="row scripted" id="preprintScope">


        <div class="col-md-12" data-bind="visible: showPreprint">
            ## TODO: Asynchronous upload, reload table on page rather than redirecting
##            <pre data-bind="text: ko.toJSON($data, null, 2)"></pre>
            <div data-bind="visible: canEdit">
##            <form data-bind="attr: { action: uploadUrl }"
            <form action='${node["api_url"]+"preprint/upload/"}'
                  method="post"
                  enctype="multipart/form-data"
                  class="dropzone"
                  id="preprint-upload-dz">
                      <span class="dz-message">
                          Click or Drag Here to Upload Files
                        </span>
            </form>
        </div>
            <script>
                $script.ready(['dropzone','preprint'], function() {
                    Dropzone.options.preprintUploadDz = {
                        paramname: 'file',
                        acceptedFiles: 'application/pdf',
                        init: function() {
                            this.on("complete", function(file) { koPreprint.viewModel.fetchFromServer(); });
##                            this.on("addedfile", function(file) { koPreprint.viewModel.uploading(true); });
##                            this.on("queuecomplete", function(file) { koPreprint.viewModel.uploading(false) });
                            this.on("queuecomplete", function(file) { koPreprint.viewModel.fetchFromServer(); });
                        }
                    };
                });
            </script>
            <div class="col-md-4">
                <div data-bind="visible: uploading">Uploading!</div>
                <table class="table table-striped" id="file-version-history">
                    ## TODO this stuff copied from osffiles_view_file.mako

                    <thead>
                    <tr>
                        <th>Version</th>
                        <!-- <th>Date</th> --> <!-- TODO: add this data to api -->
                        <!-- <th>User</th> <!-- TODO: add this data to api -->
                        <th colspan=2>Download</th><!-- TODO: add download count to api -->
                    </tr>
                    </thead>

                    <tbody>
                    <!-- ko foreach: versions -->
                    <tr>
                        <td>
                            {{version}}
                        </td>
                        <td>
                            <a href="{{url}}" download="{{version}}">
                                <i class="icon-download-alt"></i>
                            </a>
                        </td>
                    </tr>
                    <!-- /ko -->
                    </tbody>

                </table>
            </div>



        </div>
        ##        <pre data-bind="text: ko.toJSON($data, null, 2)"></pre>
            </div>

    <div class="col-md-12">
        <!-- Citations -->
        <div class="citations">
            <span class="citation-label">Citation:</span>
            <span>${node['display_absolute_url']}</span>
            <a href="#" class="citation-toggle" style="padding-left: 10px;">more</a>
            <dl class="citation-list">
                <dt>APA</dt>
                <dd class="citation-text">${node['citations']['apa']}</dd>
                <dt>MLA</dt>
                <dd class="citation-text">${node['citations']['mla']}</dd>
                <dt>Chicago</dt>
                <dd class="citation-text">${node['citations']['chicago']}</dd>
            </dl>
        </div>

        <hr />

        <div class="tags">
            <input name="node-tags" id="node-tags" value="${','.join([tag for tag in node['tags']]) if node['tags'] else ''}" />
        </div>

        <hr />

        <div class="logs">
            <div id='logScope'>
                <%include file="log_list.mako"/>
                <a class="moreLogs" data-bind="click: moreLogs, visible: enableMoreLogs">more</a>
            </div><!-- end #logScope -->
        </div>

    </div>

</%def>




<%def name="javascript()">
    % if rendered is None:
        <script type="text/javascript">
            $script(['/static/js/filerenderer.js'], function() {
                FileRenderer.start('${render_url}', '#fileRendered');
            });
        </script>
    % endif
</%def>


<%def name="stylesheets()">
    ${parent.stylesheets()}
    % for style in addon_widget_css:
        <link rel="stylesheet" href="${style}" />
    % endfor
</%def>


<%def name="javascript_bottom()">

    ${parent.javascript_bottom()}

    % for script in addon_widget_js:
        <script type="text/javascript" src="${script}"></script>
    % endfor

    <script type="text/javascript">
            <% import json %>

        $script(['/static/js/nodeControl.js'], 'nodeControl');
        $script(['/static/js/logFeed.js'], 'logFeed');
        $script(['/static/js/contribAdder.js'], 'contribAdder');
        $script(['/static/js/pointers.js'], 'pointers');
        $script(['/static/js/preprint.js']);

        var $comments = $('#comments');
        var userName = '${user_full_name}';
        var canComment = ${'true' if user['can_comment'] else 'false'};
        var hasChildren = ${'true' if node['has_children'] else 'false'};

        if ($comments.length) {
            $script(['/static/js/commentpane.js', '/static/js/comment.js'], 'comments');
            $script.ready('comments', function () {
                var commentPane = new CommentPane('#commentPane');
                Comment.init('#comments', userName, canComment, hasChildren);
            });

        }

        // Import modules

            ## TODO: Move this logic into badges add-on
            % if 'badges' in addons_enabled and badges and badges['can_award']:
                            $script(['/static/addons/badges/badge-awarder.js'], function() {
                                attachDropDown('${'{}badges/json/'.format(user_api_url)}');
                            });
        % endif

        // TODO: Put these in the contextVars object below
        var nodeId = '${node['id']}';
        var userApiUrl = '${user_api_url}';
        var nodeApiUrl = '${node['api_url']}';
        // Mako variables accessible globally
        window.contextVars = {
            currentUser: {
                ## TODO: Abstract me
                username: ${json.dumps(user['username']) | n},
                id: '${user_id}'
            },
            node: {
                ## TODO: Abstract me
                title: ${json.dumps(node['title']) | n}
            }
        };

        $(function() {

            $logScope = $('#logScope');
            $linkScope = $('#linkScope');
            // Get project data from the server and initiate KO modules
            $.getJSON(nodeApiUrl, function(data){
                        // Initialize nodeControl and logFeed on success
                        $script
                                .ready('nodeControl', function() {
                                    var nodeControl = new NodeControl('#projectScope', data);
                                })
                                .ready('logFeed', function() {
                                    if ($logScope.length) { // Render log feed if necessary
                                        var logFeed = new LogFeed('#logScope', data.node.logs, {'url':nodeApiUrl+'log/', 'hasMoreLogs': data.node.has_more_logs});
                                    }
                                });
                        // If user is a contributor, initialize the contributor modal
                        // controller
                        if (data.user.can_edit) {
                            $script.ready('contribAdder', function() {
                                var contribAdder = new ContribAdder(
                                        '#addContributors',
                                        data.node.title,
                                        data.parent_node.id,
                                        data.parent_node.title
                                );
                            });
                        }

                    }
            );
            var linksModal = $('#showLinks')[0];
            var linksVM = new LinksViewModel(linksModal);
            ko.applyBindings(linksVM, linksModal);

        });

        $script.ready('pointers', function() {
            var pointerManager = new PointerManager('#addPointer', contextVars.node.title);
        });

        // Make unregistered contributors claimable
            % if not user.get('is_contributor'):
                $script(['/static/js/accountClaimer.js'], function() {
                    var accountClaimer = new OSFAccountClaimer('.contributor-unregistered');
                });
            % endif

    </script>
    % if node.get('is_public') and node.get('piwik_site_id'):
<script type="text/javascript">

    $(function() {
        // Note: Don't use cookies for global site ID; cookies will accumulate
        // indefinitely and overflow uwsgi header buffer.
        $.osf.trackPiwik('${ piwik_host }', ${ node['piwik_site_id'] });
    });
    </script>
    % endif

    ## Todo: Move to project.js
    <script>

        $(document).ready(function() {
            // Tooltips
            $('[data-toggle="tooltip"]').tooltip();

            // Tag input
            $('#node-tags').tagsInput({
                width: "100%",
                interactive:${'true' if user["can_edit"] else 'false'},
                onAddTag: function(tag){
                    $.ajax({
                        url: "${node['api_url']}" + "addtag/" + tag + "/",
                        type: "POST",
                        contentType: "application/json"
                    });
                },
                onRemoveTag: function(tag){
                    $.ajax({
                        url: "${node['api_url']}" + "removetag/" + tag + "/",
                        type: "POST",
                        contentType: "application/json"
                    });
                }
            });
        });
    </script>

    <script>
        $script.ready('preprint', function() {
            var url = '${node["api_url"]}' + "preprint/";
            // TODO: Not sure this is great
            // Adds koPreprint to the global namespace so we can ask it to update the viewmodel
            koPreprint = new PreprintViewModel('#preprintScope', url);
        });
    </script>
</%def>
