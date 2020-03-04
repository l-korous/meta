const { promisify } = require('util');
exports.initialize = function (app, appConfig, Busboy, path, fs, shell) {
    const writeFile = promisify(fs.writeFile);

    function makeid(length) {
       var result           = '';
       var characters       = 'abcdefghijklmnopqrstuvwxyz0123456789';
       var charactersLength = characters.length;
       for ( var i = 0; i < length; i++ ) {
          result += characters.charAt(Math.floor(Math.random() * charactersLength));
       }
       return result;
    }
    
    function get_full_model_path(model_id) {
        return path.join(__dirname, 'tmp', model_id);
    }
    
    function get_full_target_path(target_id) {
        return path.join(__dirname, 'targets', target_id);
    }
    
    function get_full_docker_path() {
        return path.join(__dirname, 'public', 'docker');
    }
    
    function get_templates_path() {
        return path.join(__dirname, 'templates');
    }
    
    function get_bin_path() {
        return path.join(__dirname, 'bin');
    }
        
    function shell_run_script(script_name, fn) {
        if(process.platform === 'win32') {
            return shell.exec('bash -c "./' + script_name + '"', fn);
        }
        else
            return shell.exec('./' + script_name, fn);
    }
        
    function safe_shell(cmd, fn) {
        var { stdout, stderr, code } = fn();
        if(code != 0) {
            console.log('Command: ', cmd);
            console.log('Exit code:', code);
            console.log('Program output:', stdout);
            console.log('Program stderr:', stderr);
            throw stderr;
        }
        return { stdout: stdout, stderr: stderr, code: code };
    }
    
    async function put_model(model) {
        var model_id = makeid(10);
        await writeFile(get_full_model_path(model_id), model);
        return model_id;
    }
    
    function get_model(model_id) {
        try {
            return fs.readFileSync(get_full_model_path(model_id), 'utf8')
        } catch(err) {
            console.error(err);
        }
    }
    
    function delete_model(model_id) {
        try {
            fs.unlinkSync(get_full_model_path(model_id))
        } catch(err) {
            console.error(err)
        }
    }
    
    const awaitHandlerFactory = (middleware) => {
      return async (req, res, next) => {
        try {
          await middleware(req, res, next)
        } catch (err) {
          next(err)
        }
      }
    }
    
    app.get("/api/model-xml/:model_id", function(req , res) {
        res.send(get_model(req.params['model_id']));
    });
    
    app.post("/api/model-xml", awaitHandlerFactory(async function(req , res) {
        var model_id = await put_model(req.body);
        res.send(model_id);
    }));
    
    app.delete("/api/model-xml/:model_id", function(req , res) {
        delete_model(req.params['model_id']);
        res.send();
    });
    
    app.post("/api/deploy-model-xml", awaitHandlerFactory(async function(req , res) {
        var model_id = await put_model(req.body);
         
        safe_shell('rm target', () => shell.rm('-rf', get_full_target_path(model_id)));
        safe_shell('mkdir target', () => shell.mkdir('-p', get_full_target_path(model_id)));
        safe_shell('cd templates', () => shell.cd(get_templates_path()));
        
        ['sql', 'js', 'html'].forEach(function(ext) {
            console.log('Generating artefacts - ' + ext);
            safe_shell('mkdir target - ' + ext, () => shell.mkdir('-p', path.join(get_full_target_path(model_id), ext)));
            shell.pushd('-q', ext);
            var file_array = shell.ls('*.xslt');
            file_array.forEach(function(template) {
                safe_shell('generate - ' + template, () => shell.exec('java -jar ' + path.join(get_bin_path(), 'saxon9he.jar') + ' -s:' + get_full_model_path(model_id) + ' -xsl:' + path.join(get_templates_path(), ext, template) + ' -o:' + path.join(get_full_target_path(model_id), ext, template + '.' + ext).replace('.xslt', '')));
            });
            shell.popd('-q');
        });
        
        console.log('Generating artefacts - special');
        [ { template: 'deploy.xslt', target: 'deploy.sh' }, { template: 'deploy_mssql.xslt', target: 'sql/deploy_mssql.sh' }, { template: 'Dockerfile.xslt', target: 'js/Dockerfile' } ].forEach(function(custom_template) {
            safe_shell('generate - ' + custom_template.template, () => shell.exec('java -jar ' + path.join(get_bin_path(), 'saxon9he.jar') + ' -s:' + get_full_model_path(model_id) + ' -xsl:' + path.join(get_templates_path(), custom_template.template) + ' -o:' + path.join(get_full_target_path(model_id), custom_template.target)));
        });
        
        safe_shell('mkdir html', () => shell.mkdir('-p', path.join(get_full_target_path(model_id), 'js', 'public', 'app')));
        
        safe_shell('mv html', () => shell.mv(path.join(get_full_target_path(model_id), 'html', '*'), path.join(get_full_target_path(model_id), 'js', 'public', 'app')));
        
        safe_shell('cd target', () => shell.cd(get_full_target_path(model_id)));
        
        safe_shell('deploy.sh', () => shell_run_script('deploy.sh'));
        
        var docker_image_response = safe_shell('save_docker_img.sh', () => shell_run_script('save_docker_img.sh'));
        var docker_image_name = docker_image_response.stdout;
        
        safe_shell('mv docker image', () => shell.mv(docker_image_name, get_full_docker_path()));
        res.send({dockerUrl: docker_image_name});
    }));
};
